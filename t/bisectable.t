#!/usr/bin/env perl6
BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;
%*ENV<TESTABLE> = 1;

use lib ‘t/lib’;
use Test;
use Testable;

my $t = Testable.new(bot => ‘./Bisectable.p6’);

# Help messages

$t.test(‘help message’,
        “{$t.bot-nick}, helP”,
        “{$t.our-nick}, Like this: bisectable6: old=2015.12 new=HEAD exit 1 if (^∞).grep(\{ last })[5] // 0 == 4”
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Bisectable’);


$t.test(‘help message’,
        “{$t.bot-nick},   HElp?  ”,
        “{$t.our-nick}, Like this: bisectable6: old=2015.12 new=HEAD exit 1 if (^∞).grep(\{ last })[5] // 0 == 4”
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Bisectable’);

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

$t.test(‘“bisect:” shortcut’,
        ‘bisect: url’,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘“bisect,” shortcut’,
        ‘bisect, url’,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘“bisect6:” shortcut’,
        ‘bisect6: url’,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘“bisect6,” shortcut’,
        ‘bisect6, url’,
        “{$t.our-nick}, https://github.com/perl6/whateverable”);

$t.test(‘“bisect” shortcut does not work’,
        ‘bisect url’);

$t.test(‘“bisect6” shortcut does not work’,
        ‘bisect6 url’);

$t.test(‘source link’,
        “{$t.bot-nick}: wIki”,
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Bisectable”);

$t.test(‘source link’,
        “{$t.bot-nick}:   wiki? ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Bisectable”);

# Basics

$t.test(‘bisect by exit code’,
        ‘bisect: exit 1 unless $*VM.version.Str.starts-with(‘2015’)’,
        /^ <me($t)>‘, Bisecting by exit code (old=2015.12 new=’<sha>‘). Old exit code: 0’ $/,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-02-04) https://github.com/rakudo/rakudo/commit/241e6c06a9ec4c918effffc30258f2658aad7b79”);

$t.test(‘inverted exit code’,
        ‘bisect: exit 1 if     $*VM.version.Str.starts-with(‘2015’)’,
        /^ <me($t)>‘, Bisecting by exit code (old=2015.12 new=’<sha>‘). Old exit code: 1’ $/,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-02-04) https://github.com/rakudo/rakudo/commit/241e6c06a9ec4c918effffc30258f2658aad7b79”);

$t.test(‘bisect by output’,
        ‘bisect: say $*VM.version.Str.split(‘.’).first # same but without proper exit codes’,
        /^ <me($t)>‘, Bisecting by output (old=2015.12 new=’<sha>‘) because on both starting points the exit code is 0’ $/,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-02-04) https://github.com/rakudo/rakudo/commit/241e6c06a9ec4c918effffc30258f2658aad7b79”);

$t.test(‘bisect by exit signal’,
        ‘bisect: old=2015.10 new=2015.12 Buf.new(0xFE).decode(‘utf8-c8’) # RT 126756’,
        “{$t.our-nick}, Bisecting by exit signal (old=2015.10 new=2015.12). Old exit signal: 0 (None)”,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2015-11-09) https://github.com/rakudo/rakudo/commit/3fddcb57f66a44d1a8adb7ecee1a3b403ab9f5d8”);

$t.test(‘inverted exit signal’,
        ‘bisect: Buf.new(0xFE).decode(‘utf8-c8’) # RT 126756’,
        /^ <me($t)>‘, Bisecting by exit signal (old=2015.12 new=’<sha>‘). Old exit signal: 11 (SIGSEGV)’ $/,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-04-01) https://github.com/rakudo/rakudo/commit/a87fb43b6c85a496ef0358197625b5b417a0d372”);

$t.test(‘nothing to bisect’,
        ‘bisect: say ‘hello world’; exit 42’,
        /^ <me($t)>‘, On both starting points (old=2015.12 new=’<sha>‘) the exit code is 42 and the output is identical as well’ $/,
        “{$t.our-nick}, Output on both points: «hello world»”);

$t.test(‘nothing to bisect, segmentation fault everywhere’,
        ‘bisect: old=2016.02 new=2016.03 Buf.new(0xFE).decode(‘utf8-c8’)’,
        “{$t.our-nick}, On both starting points (old=2016.02 new=2016.03) the exit code is 0, exit signal is 11 (SIGSEGV) and the output is identical as well”,
        “{$t.our-nick}, Output on both points: «»”);

$t.test(‘large output is uploaded’,
        ‘bisect: .say for ^1000; exit 5’,
        /^ <me($t)>‘, On both starting points (old=2015.12 new=’<sha>‘) the exit code is 5 and the output is identical as well’ $/,
        “{$t.our-nick}, https://whatever.able/fakeupload”);

$t.test(‘exit code on old revision is 125’,
        ‘bisect: exit 125 if $*VM.gist eq ‘moar (2015.12)’’,
        “{$t.our-nick}, Exit code on “old” revision is 125, which means skip this commit. Please try another old revision”);

$t.test(‘exit code on new revision is 125’,
        ‘bisect: exit 125 unless $*VM.gist eq ‘moar (2015.12)’’,
        “{$t.our-nick}, Exit code on “new” revision is 125, which means skip this commit. Please try another new revision”);

# Custom starting points

$t.test(‘custom starting points’,
        ‘bisect: old=2016.02 new 2016.03 say (^∞).grep({ last })[5]’,
        “{$t.our-nick}, Bisecting by output (old=2016.02 new=2016.03) because on both starting points the exit code is 0”,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-03-18) https://github.com/rakudo/rakudo/commit/6d120cab6d0bf55a3c96fd3bd9c2e841e7eb99b0”);

$t.test(‘custom starting points using “bad” and “good” terms’,
        ‘bisect: good 2016.02 bad=2016.03 say (^∞).grep({ last })[5]’,
        “{$t.our-nick}, Bisecting by output (old=2016.02 new=2016.03) because on both starting points the exit code is 0”,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-03-18) https://github.com/rakudo/rakudo/commit/6d120cab6d0bf55a3c96fd3bd9c2e841e7eb99b0”);

$t.test(‘swapped old and new revisions’,
        ‘bisect: old 2016.03 new 2016.02 say (^∞).grep({ last })[5]’,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, bisect init failure. See the log for more details”);

# Special characters
#`{ What should we do with colors?
$t.test(‘special characters’,
        ‘bisect: say (.chr for ^128).join’,
        /^ <me($t)>‘, On both starting points (old=2015.12 new=’<sha>‘) the exit code is 0 and the output is identical as well’ $/,
        “{$t.our-nick}, Output on both points: ” ~ ‘«␀␁␂␃␄␅␆␇␈␉␤␋␌␍␎␏␐␑␒␓␔␕␖␗␘␙␚␛␜␝␞␟ !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~␡»’);
}

$t.test(‘␤ works like an actual newline’,
        ‘bisect: # newline test ␤ say ‘hello world’; exit 42’,
        /^ <me($t)>‘, On both starting points (old=2015.12 new=’<sha>‘) the exit code is 42 and the output is identical as well’ $/,
        “{$t.our-nick}, Output on both points: «hello world»”);

# URLs

$t.test(‘fetching code from urls’,
        ‘bisect: https://gist.githubusercontent.com/AlexDaniel/147bfa34b5a1b7d1ebc50ddc32f95f86/raw/9e90da9f0d95ae8c1c3bae24313fb10a7b766595/test.p6’,
        “{$t.our-nick}, Successfully fetched the code from the provided URL.”,
        /^ <me($t)>‘, On both starting points (old=2015.12 new=’<sha>‘) the exit code is 0 and the output is identical as well’ $/,
        “{$t.our-nick}, Output on both points: «url test»”);

$t.test(‘wrong url’,
        ‘bisect: http://github.org/sntoheausnteoahuseoau’,
        “{$t.our-nick}, It looks like a URL, but for some reason I cannot download it (HTTP status line is 404 Not Found).”);

$t.test(‘wrong mime type’,
        ‘bisect: https://www.wikipedia.org/’,
        “{$t.our-nick}, It looks like a URL, but mime type is ‘text/html’ while I was expecting something with ‘text/plain’ or ‘perl’ in it. I can only understand raw links, sorry.”);

# Did you mean … ?

$t.test(‘Did you mean “HEAD” (new)?’,
        ‘bisect: new=DEAD say 42’,
        “{$t.our-nick}, Cannot find revision “DEAD” (did you mean “HEAD”?)”);
$t.test(‘Did you mean “HEAD” (old)?’,
        ‘bisect: old=DEAD say 42’,
        “{$t.our-nick}, Cannot find revision “DEAD” (did you mean “HEAD”?)”);
$t.test(‘Did you mean some tag? (new)’,
        ‘bisect: new=2015.21 say 42’,
        “{$t.our-nick}, Cannot find revision “2015.21” (did you mean “2015.12”?)”);
$t.test(‘Did you mean some tag? (old)’,
        ‘bisect: old=2015.21 say 42’,
        “{$t.our-nick}, Cannot find revision “2015.21” (did you mean “2015.12”?)”);
$t.test(‘Did you mean some commit? (new)’,
        ‘bisect: new=a7L479b49dbd1 say 42’,
        “{$t.our-nick}, Cannot find revision “a7L479b49dbd1” (did you mean “a71479b”?)”);
$t.test(‘Did you mean some commit? (old)’,
        ‘bisect: old=a7L479b49dbd1 say 42’,
        “{$t.our-nick}, Cannot find revision “a7L479b49dbd1” (did you mean “a71479b”?)”);

# Extra tests

$t.test(‘another working query’,
        ‘bisect: new=d3acb938 try { NaN.Rat == NaN; exit 0 }; exit 1’,
        “{$t.our-nick}, Bisecting by exit code (old=2015.12 new=d3acb93). Old exit code: 0”,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-05-02) https://github.com/rakudo/rakudo/commit/e2f1fa735132b9f43e7aa9390b42f42a17ea815f”);

$t.test(‘last working query’, # keep it last in this file
        ‘bisect: for ‘q b c d’.words -> $a, $b { }; CATCH { exit 0 }; exit 1’,
        /^ <me($t)>‘, Bisecting by exit code (old=2015.12 new=’<sha>‘). Old exit code: 0’ $/,
        “{$t.our-nick}, bisect log: https://whatever.able/fakeupload”,
        “{$t.our-nick}, (2016-03-01) https://github.com/rakudo/rakudo/commit/1b6c901c10a0f9f65ac2d2cb8e7a362915fadc61”);

done-testing;
END $t.end;
