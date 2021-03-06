# Copyright © 2016-2017
#     Aleks-Daniel Jakimenko-Aleksejev <alex.jakimenko@gmail.com>
# Copyright © 2016
#     Daniel Green <ddgreen@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use File::Directory::Tree;
use File::Temp;
use HTTP::UserAgent;
use IRC::Client::Message;
use IRC::Client;
use IRC::TextColor;
use JSON::Fast;
use Pastebin::Gist;
use Terminal::ANSIColor;
use Text::Diff::Sift4;

use Misc;

constant RAKUDO = ‘./rakudo’.IO.absolute;
constant CONFIG = ‘./config.json’.IO.absolute;
constant SOURCE = ‘https://github.com/perl6/whateverable’;
constant WIKI   = ‘https://github.com/perl6/whateverable/wiki/’;
constant WORKING-DIRECTORY = ‘.’; # TODO not supported yet
constant ARCHIVES-LOCATION = “{WORKING-DIRECTORY}/builds”.IO.absolute;
constant BUILDS-LOCATION   = ‘/tmp/whateverable/’;

constant MESSAGE-LIMIT is export = 260;
constant COMMITS-LIMIT = 500;
constant PARENTS = ‘AlexDaniel’, ‘MasterDuke’;

constant Message = IRC::Client::Message;

unit role Whateverable does IRC::Client::Plugin does Helpful;

has $.timeout is rw = 10;
has $!stdin = slurp ‘stdin’;
has $!bad-releases = set ‘2016.01’, ‘2016.01.1’;

multi method irc-to-me(Message $msg where .text ~~
                       #↓ Matches only one space on purpose (for whitespace-only stdin)
                       /:i^ [stdin] [‘ ’|‘=’] [clear|delete|reset|unset] $/) {
    $!stdin = slurp ‘stdin’;
    ‘STDIN is reset to the default value’
}

multi method irc-to-me(Message $msg where .text ~~ /:i^ [stdin] [‘ ’|‘=’] $<stdin>=.* $/) {
    my ($ok, $new-stdin) = self.process-code(~$<stdin>, $msg);
    if $ok {
        $!stdin = $new-stdin;
        “STDIN is set to «{shorten $!stdin, 200}»” # TODO is 200 a good limit?
    } else {
        ‘Nothing done’
    }
}

multi method irc-to-me(Message $    where .text ~~ /:i^ [source|url] ‘?’? $/ --> SOURCE) {}
multi method irc-to-me(Message $    where .text ~~ /:i^ wiki ‘?’? $/) { self.get-wiki-link }
multi method irc-to-me(Message $msg where .text ~~ /:i^ help ‘?’? $/) {
    self.help($msg) ~ “ # See wiki for more examples: {self.get-wiki-link}”
}
multi method irc-notice-me( $ --> ‘Sorry, it is too private here’) {} # TODO issue #16
multi method irc-privmsg-me($ --> ‘Sorry, it is too private here’) {} # TODO issue #16
multi method irc-to-me($) {
    ‘I cannot recognize this command. See wiki for some examples: ’ ~ self.get-wiki-link
}

method get-wiki-link { WIKI ~ self.^name }

method beg-for-help($msg) {
    warn ‘Please help me!’;
    $msg.irc.send-cmd: ‘PRIVMSG’, $msg.channel, ‘Hey folks. What's up with me?’,
                       :server($msg.server), :prefix(PARENTS.join(‘, ’) ~ ‘: ’)
}

method get-short-commit($original-commit) { # TODO not an actual solution tbh
    $original-commit ~~ /^ <xdigit> ** 7..40 $/
    ⁇ $original-commit.substr(0, 7)
    ‼ $original-commit
}

method get-output(*@run-args, :$timeout = $!timeout, :$stdin) {
    my $out = Channel.new; # TODO switch to some Proc :merge thing once it is implemented
    my $proc = Proc::Async.new: |@run-args, w => defined $stdin;
    $proc.stdout.tap: -> $v { $out.send: $v };
    $proc.stderr.tap: -> $v { $out.send: $v };

    my $s-start = now;
    my $promise = $proc.start: scheduler => BEGIN ThreadPoolScheduler.new;
    with $stdin {
        $proc.print: $_;
        $proc.close-stdin;
    }

    await Promise.anyof: Promise.in($timeout), $promise;
    my $s-end = now;

    if not $promise.status ~~ Kept { # timed out
        $proc.kill; # TODO sends HUP, but should kill the process tree instead
        $out.send: “«timed out after $timeout seconds, output»: ”;
    }
    try sink await $promise; # wait until it is actually stopped
    $out.close;
    %(
        output    => $out.list.join.chomp,
        exit-code => $promise.result.exitcode,
        signal    => $promise.result.signal,
        time      => $s-end - $s-start,
    )
}

method build-exists($full-commit-hash, :$backend=‘rakudo-moar’) {
    “{ARCHIVES-LOCATION}/$backend/$full-commit-hash.zst”.IO ~~ :e
}

method get-similar($tag-or-hash, @other?) {
    my $old-dir = $*CWD;
    LEAVE chdir $old-dir;
    chdir RAKUDO;

    my @options = @other;
    my @tags = self.get-output(‘git’, ‘tag’, ‘--format=%(*objectname)/%(objectname)/%(refname:strip=2)’,
                               ‘--sort=-taggerdate’)<output>.lines
                               .map(*.split(‘/’))
                               .grep({ self.build-exists: .[0] || .[1] })
                               .map(*[2]);

    my $cutoff = $tag-or-hash.chars max 7;
    my @commits = self.get-output(‘git’, ‘rev-list’, ‘--all’, ‘--since=2014-01-01’)<output>
                      .lines.map(*.substr: 0, $cutoff);

    # flat(@options, @tags, @commits).min: { sift4($_, $tag-or-hash, 5, 8) }
    my $ans = ‘HEAD’;
    my $ans_min = ∞;

    for flat @options, @tags, @commits {
        my $dist = sift4 $_, $tag-or-hash, $cutoff;
        if $dist < $ans_min {
            $ans = $_;
            $ans_min = $dist;
        }
    }
    $ans
}

method run-smth($full-commit-hash, $code, :$backend=‘rakudo-moar’) {
    my $build-path   = “{  BUILDS-LOCATION}/$backend/$full-commit-hash”;
    my $archive-path = “{ARCHIVES-LOCATION}/$backend/$full-commit-hash.zst”;
    # lock on the destination directory to make
    # sure that other bots will not get in our way.
    while run(‘mkdir’, ‘--’, $build-path).exitcode ≠ 0 {
        sleep 0.5;
        # Uh, wait! Does it mean that at the same time we can use only one
        # specific build? Yes, and you will have to wait until another bot
        # deletes the directory so that you can extract it back again…
        # There are some ways to make it work, but don't bother. Instead,
        # we should be doing everything in separate isolated containers (soon),
        # so this problem will fade away.
    }
    my $proc = run :out, :bin, ‘pzstd’, ‘-dqc’, ‘--’, $archive-path;
    run :in($proc.out), :bin, ‘tar’, ‘x’, ‘--absolute-names’;

    my $return = $code($build-path); # basically, we wrap around $code

    rmtree $build-path;

    $return
}

method run-snippet($full-commit-hash, $file, :$backend=‘rakudo-moar’, :$timeout = $!timeout) {
    self.run-smth: :$backend, $full-commit-hash, -> $path {
        my $out;
        if “$path/bin/perl6”.IO !~~ :e {
            $out = %(output => ‘Commit exists, but a perl6 executable could not be built for it’,
                     exit-code => -1, signal => -1, time => -1,)
        } else {
            $out = self.get-output: “$path/bin/perl6”,
                                    ‘--setting=RESTRICTED’, ‘--’, $file,
                                    :$!stdin, :$timeout
        }
        $out
    }
}

method get-commits($config) {
    my $old-dir = $*CWD;
    LEAVE chdir $old-dir;
    my @commits;

    if $config.contains: ‘,’ {
        @commits = $config.split: ‘,’;
    } elsif $config ~~ /^ $<start>=\S+ ‘..’ $<end>=\S+ $/ {
        chdir RAKUDO; # goes back in LEAVE
        if run(:out(Nil), ‘git’, ‘rev-parse’, ‘--verify’, $<start>).exitcode ≠ 0 {
            return “Bad start, cannot find a commit for “$<start>””;
        }
        if run(:out(Nil), ‘git’, ‘rev-parse’, ‘--verify’, $<end>).exitcode   ≠ 0 {
            return “Bad end, cannot find a commit for “$<end>””;
        }
        my $result = self.get-output: ‘git’, ‘rev-list’, “$<start>^..$<end>”; # TODO unfiltered input
        return ‘Couldn't find anything in the range’ if $result<exit-code> ≠ 0;
        @commits = $result<output>.lines;
        my $num-commits = @commits.elems;
        return “Too many commits ($num-commits) in range, you're only allowed {COMMITS-LIMIT}” if $num-commits > COMMITS-LIMIT
    } elsif $config ~~ /:i ^ [ releases | v? 6 \.? c ] $/ {
        @commits = self.get-tags: ‘2015-12-24’
    } elsif $config ~~ /:i ^ all $/ {
        @commits = self.get-tags: ‘2014-01-01’
    } elsif $config ~~ /:i ^ compare \s $<commit>=\S+ $/ {
        @commits = $<commit>
    } else {
        @commits = $config
    }

    return Nil, |@commits # TODO throw exceptions instead of doing this
}

method get-tags($date) {
    my $old-dir = $*CWD;
    chdir RAKUDO;
    LEAVE chdir $old-dir;

    my @tags = <HEAD>;
    my %seen;
    for self.get-output(‘git’, ‘log’, ‘--pretty="%d"’,
                        ‘--tags’, ‘--no-walk’, “--since=$date”)<output>.lines -> $tag {
        next unless $tag ~~ /:i ‘tag:’ \s* ((\d\d\d\d\.\d\d)[\.\d\d?]?) /; # TODO use tag -l
        next if $!bad-releases{$0}:exists;
        next if %seen{$0[0]}++;
        @tags.push($0)
    }

    @tags.reverse
}

method to-full-commit($commit, :$short = False) {
    my $old-dir = $*CWD;
    chdir RAKUDO;
    LEAVE chdir $old-dir;

    return if run(:out(Nil), ‘git’, ‘rev-parse’, ‘--verify’, $commit).exitcode ≠ 0; # make sure that $commit is valid

    my $result = self.get-output: |(‘git’, ‘rev-list’, ‘-1’, # use rev-list to handle tags
                                  ($short ⁇ ‘--abbrev-commit’ ‼ Empty), $commit);

    return if     $result<exit-code> ≠ 0;
    return unless $result<output>;
    $result<output>
}

method write-code($code) {
    my ($filename, $filehandle) = tempfile :!unlink;
    $filehandle.print: $code;
    $filehandle.close;
    $filename
}

method process-url($url, $message) {
    my $ua = HTTP::UserAgent.new;
    my $response;
    try {
        $response = $ua.get: $url;
        CATCH {
            return 0, ‘It looks like a URL, but for some reason I cannot download it’
                          ~ “ ({.message})”
        }
    }

    if not $response.is-success {
        return 0, ‘It looks like a URL, but for some reason I cannot download it’
                      ~ “ (HTTP status line is {$response.status-line}).”
    }
    if not $response.content-type.contains: any ‘text/plain’, ‘perl’ {
        return 0, “It looks like a URL, but mime type is ‘{$response.content-type}’”
                      ~ ‘ while I was expecting something with ‘text/plain’ or ‘perl’’
                      ~ ‘ in it. I can only understand raw links, sorry.’
    }
    my $body = $response.decoded-content;

    $message.reply: ‘Successfully fetched the code from the provided URL.’;
    return 1, $body
}

method process-code($code is copy, $message) {
    if $code ~~ m{^ ( ‘http’ s? ‘://’ \S+ ) } {
        my ($succeeded, $response) = self.process-url(~$0, $message);
        return 0, $response unless $succeeded;
        $code = $response
    } else {
        $code .= subst: :g, ‘␤’, “\n”
    }
    return 1, $code
}

multi method filter($response where (.encode.elems > MESSAGE-LIMIT
                                     or defined .?additional-files
                                     or (!~$_ and $_ ~~ ProperStr))) {
    # Here $response is a Str with a lot of stuff mixed in (possibly)
    my $description = ‘Whateverable’;
    my $text = colorstrip $response.?long-str // ~$response;
    my %files;
    %files<result> = $text if $text;
    %files.push: $_ with $response.?additional-files;

    if $response ~~ Reply {
        $description = $response.msg.server.current-nick;
        %files<query> = $_ with $response.?msg.text;
    }
    my $url = self.upload: %files, public => !%*ENV<DEBUGGABLE>, :$description;
    $url = $response.link-msg()($url) if $response ~~ PrettyLink;
    $url
}

multi method filter($text is copy) {
    ansi-to-irc($text).trans:
        “\n” => ‘␤’,
        3.chr => 3.chr, 0xF.chr => 0xF.chr, # keep these for IRC colors
        |((^32)».chr Z=> (0x2400..*).map(*.chr)), # convert all unreadable ASCII crap
        127.chr => ‘␡’, /<:Cc>/ => ‘␦’
}

method upload(%files is copy, :$description = ‘’, Bool :$public = True) {
    return ‘https://whatever.able/fakeupload’ if %*ENV<TESTABLE>;

    state $config = from-json slurp CONFIG;
    %files = %files.pairs.map: { .key => %( ‘content’ => .value ) }; # github format

    my $gist = Pastebin::Gist.new(token => $config<access_token>);
    return $gist.paste: %files, desc => $description, public => $public
}

method selfrun($nick is copy, @alias?) {
    $nick ~= ‘test’ if %*ENV<DEBUGGABLE>;
    .run with IRC::Client.new(
        :$nick
        :userreal($nick.tc)
        :username($nick.substr(0, 3) ~ ‘-able’)
        :password(?%*ENV<TESTABLE> ⁇ ‘’ ‼ from-json(slurp CONFIG)<irc-login irc-password>.join(‘:’))
        :@alias
        :host(%*ENV<TESTABLE> ⁇ ‘127.0.0.1’ ‼ ‘wilhelm.freenode.net’)
        :channels(%*ENV<DEBUGGABLE> ⁇ <#whateverable> ‼ <#perl6 #perl6-dev #whateverable #zofbot>)
        :debug(?%*ENV<DEBUGGABLE>)
        :plugins(self)
        :filters( -> |c { self.filter(|c) } )
    )
}

# vim: expandtab shiftwidth=4 ft=perl6
