#!/usr/bin/env perl6
BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;
%*ENV<TESTABLE> = 1;

use lib ‘t/lib’;
use Test;
use IRC::Client;
use Testable;

my $t = Testable.new(bot => ‘./Evalable.p6’);

# Help messages

$t.test(‘help message’,
        “{$t.bot-nick}, helP”,
        “{$t.our-nick}, Like this: {$t.bot-nick}: say ‘hello’; say ‘world’”
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Evalable’);

$t.test(‘help message’,
        “{$t.bot-nick},   HElp?  ”,
        “{$t.our-nick}, Like this: {$t.bot-nick}: say ‘hello’; say ‘world’”
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Evalable’);

$t.test(‘source link’,
        “{$t.bot-nick}: Source   ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘source link’,
        “{$t.bot-nick}:   sourcE?  ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘source link’,
        “{$t.bot-nick}:   URl ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘source link’,
        “{$t.bot-nick}:  urL?   ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘source link’,
        “{$t.bot-nick}: wIki”,
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Evalable”);

$t.test(‘source link’,
        “{$t.bot-nick}:   wiki? ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Evalable”);

# Basics

$t.test(‘basic “nick:” query’,
        “{$t.bot-nick}: say ‘hello’”,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

$t.test(‘basic “nick,” query’,
        “{$t.bot-nick}, say ‘hello’”,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

$t.test(‘“eval:” shortcut’,
        ‘eval: say ‘hello’’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

$t.test(‘“eval,” shortcut’,
        ‘eval, say ‘hello’’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

$t.test(‘“eval6:” shortcut’,
        ‘eval6: say ‘hello’’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

$t.test(‘“eval6,” shortcut’,
        ‘eval6, say ‘hello’’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

$t.test(‘“commit” shortcut does not work’,
        ‘eval say ‘hello’’);

$t.test(‘“commit6” shortcut does not work’,
        ‘eval6 HEAD say ‘hello’’);

$t.test(‘too long output is uploaded’,
        ‘eval: .say for ^1000’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «0␤1␤2␤3␤4’ <-[…]>+ ‘…»’ $/,
        “{$t.our-nick}, Full output: https://whatever.able/fakeupload”
       );

# Exit code & exit signal

$t.test(‘exit code’,
        ‘eval: say ‘foo’; exit 42’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «(exit code 42) foo»’ $/);


$t.test(‘exit signal’,
        ‘eval: use NativeCall; sub strdup(int64) is native(Str) {*}; strdup(0)’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «(signal SIGSEGV) »’ $/);

# STDIN

$t.test(‘stdin’,
        ‘eval: say lines[0]’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «♥🦋 ꒛㎲₊⼦🂴⧿⌟ⓜ≹℻ 😦⦀🌵 🖰㌲⎢➸ 🐍💔 🗭𐅹⮟⿁ ⡍㍷⽐»’ $/);

$t.test(‘set custom stdin’,
        ‘eval: stdIN custom string␤another line’,
        “{$t.our-nick}, STDIN is set to «custom string␤another line»”);

$t.test(‘test custom stdin’,
        ‘eval: dd lines’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «("custom string", "another line").Seq»’ $/);

$t.test(‘reset stdin’,
        ‘eval: stdIN rESet’,
        “{$t.our-nick}, STDIN is reset to the default value”);

$t.test(‘test stdin after reset’,
        ‘eval: say lines[0]’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «♥🦋 ꒛㎲₊⼦🂴⧿⌟ⓜ≹℻ 😦⦀🌵 🖰㌲⎢➸ 🐍💔 🗭𐅹⮟⿁ ⡍㍷⽐»’ $/);

$t.test(‘stdin line count’,
        ‘eval: say +lines’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «10»’ $/);

$t.test(‘stdin word count’,
        ‘eval: say +$*IN.words’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «100»’ $/);

$t.test(‘stdin char count’,
        ‘eval: say +slurp.chars’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «500»’ $/);

# Special characters
#`{ What should we do with colors?
$t.test(‘special characters’,
        ‘eval: say (.chr for ^128).join’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «␀␁␂␃␄␅␆␇␈␉␤␋␌␍␎␏␐␑␒␓␔␕␖␗␘␙␚␛␜␝␞␟ !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~␡»’ $/);

$t.test(‘␤ works like an actual newline’,
        ‘eval: # This is a comment ␤ say ｢hello world!｣’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello world!»’ $/);
}

# URLs

$t.test(‘fetching code from urls’,
        ‘eval: https://gist.githubusercontent.com/AlexDaniel/147bfa34b5a1b7d1ebc50ddc32f95f86/raw/9e90da9f0d95ae8c1c3bae24313fb10a7b766595/test.p6’,
        “{$t.our-nick}, Successfully fetched the code from the provided URL.”,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «url test»’ $/);

$t.test(‘wrong url’,
        ‘eval: http://github.org/sntoheausnteoahuseoau’,
        “{$t.our-nick}, It looks like a URL, but for some reason I cannot download it (HTTP status line is 404 Not Found).”);

$t.test(‘wrong mime type’,
        ‘eval: https://www.wikipedia.org/’,
        “{$t.our-nick}, It looks like a URL, but mime type is ‘text/html’ while I was expecting something with ‘text/plain’ or ‘perl’ in it. I can only understand raw links, sorry.”);


# Camelia replacement

$t.test(‘Answers on ‘m:’ when camelia is not around’,
        ‘m: say ‘42’’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «42»’ $/);

my $camelia = IRC::Client.new(:nick(‘camelia’) :host<127.0.0.1> :channels<#whateverable>);
start $camelia.run;
sleep 1;

$t.test(‘Camelia is back, be silent’,
        ‘m: say ‘43’’);

$camelia.quit;
sleep 1;

$t.test(‘Answers on ‘m:’ when camelia is not around again’,
        ‘m: say ‘44’’,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «44»’ $/);

# Extra tests

$t.test(‘last basic query, just in case’, # keep it last in this file
        “{$t.bot-nick}: say ‘hello’”,
        /^ <me($t)>‘, rakudo-moar ’<sha>‘: OUTPUT: «hello»’ $/);

done-testing;
END $t.end;
