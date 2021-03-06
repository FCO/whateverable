#!/usr/bin/env perl6
BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;
%*ENV<TESTABLE> = 1;

use lib ‘t/lib’;
use Test;
use Testable;

my $t = Testable.new(bot => ‘./Benchable.p6’);

# Help messages

$t.test(‘help message’,
        “{$t.bot-nick}, helP”,
        “{$t.our-nick}, Like this: {$t.bot-nick}: f583f22,HEAD ” ~ ｢my $a = ‘a’ x 2¹⁶; for ^1000 {my $b = $a.chop($_)}｣
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Benchable’);

$t.test(‘help message’,
        “{$t.bot-nick},   HElp?  ”,
        “{$t.our-nick}, Like this: {$t.bot-nick}: f583f22,HEAD ” ~ ｢my $a = ‘a’ x 2¹⁶; for ^1000 {my $b = $a.chop($_)}｣
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Benchable’);

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
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Benchable”);

$t.test(‘source link’,
        “{$t.bot-nick}:   wiki? ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Benchable”);

# Basics

$t.test(‘basic “nick:” query’,
        “{$t.bot-nick}: HEAD say ‘hello’”,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘basic “nick,” query’,
        “{$t.bot-nick}, HEAD say ‘hello’”,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘“bench:” shortcut’,
        ‘bench: HEAD say ‘hello’’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘“bench,” shortcut’,
        ‘bench, HEAD say ‘hello’’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘“bench6:” shortcut’,
        ‘bench6: HEAD say ‘hello’’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘“bench6,” shortcut’,
        ‘bench6, HEAD say ‘hello’’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘“bench” shortcut does not work’,
        ‘bench HEAD say ‘hello’’);

$t.test(‘“bench6” shortcut does not work’,
        ‘bench6 HEAD say ‘hello’’);

$t.test(‘specific commit’,
        ‘bench: f583f22 say $*PERL.compiler.version’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦f583f22: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘the benchmark time makes sense’,
        ‘bench: HEAD sleep 2’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ (\d+)\.\d+ <?{ $0 ≥ 2 }> ‘»’ $/,
        :30timeout);

$t.test(‘“compare” query’,
        ‘bench: compare HEAD say ‘hi’ ||| say ‘bye’’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        “{$t.our-nick}, https://whatever.able/fakeupload”);

# Ranges and multiple commits

$t.test(‘“releases” query’,
        ‘bench: releases say $*PERL’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        “{$t.our-nick}, benchmarked the given commits, now zooming in on performance differences”,
        “{$t.our-nick}, https://whatever.able/fakeupload”,
        :240timeout);

$t.test(‘“v6c” query’,
        ‘bench: v6c say $*PERL’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        “{$t.our-nick}, benchmarked the given commits, now zooming in on performance differences”,
        “{$t.our-nick}, https://whatever.able/fakeupload”,
        :240timeout);

$t.test(‘multiple commits separated by comma (three consecutive commits, so zooming in on performance differences will not create a graph’,
        “bench: b1f77c8,87bba04,79bb867 say ‘hello’”,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        “{$t.our-nick}, benchmarked the given commits, now zooming in on performance differences”,
        /^ <me($t)>‘, ¦b1f77c8: «’ \d+\.\d+ ‘» ¦87bba04: «’ \d+\.\d+ ‘» ¦79bb867: «’ \d+\.\d+ ‘»’ $/,
        :20timeout);

$t.test(‘commit~num syntax’,
        ‘bench: 2016.10~1 say $*PERL.compiler.version’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦2016.10~1: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘commit^^^ syntax’,
        ‘bench: 2016.10^^ say $*PERL.compiler.version’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦2016.10^^: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘commit..commit range syntax’,
        ‘bench: 79bb867..b1f77c8 say ‘a’ x 9999999999999999999’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦b1f77c8: «’ \d+\.\d+ ‘» ¦87bba04: «’ \d+\.\d+ ‘» ¦79bb867: «’ \d+\.\d+ ‘»’ $/,
        :20timeout);

# URLs

$t.test(‘fetching code from urls’,
        ‘bench: HEAD https://gist.githubusercontent.com/AlexDaniel/147bfa34b5a1b7d1ebc50ddc32f95f86/raw/9e90da9f0d95ae8c1c3bae24313fb10a7b766595/test.p6’,
        “{$t.our-nick}, Successfully fetched the code from the provided URL.”,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

$t.test(‘wrong url’,
        ‘bench: HEAD http://github.org/sntoheausnteoahuseoau’,
        “{$t.our-nick}, It looks like a URL, but for some reason I cannot download it (HTTP status line is 404 Not Found).”);

$t.test(‘wrong mime type’,
        ‘bench: HEAD https://www.wikipedia.org/’,
        “{$t.our-nick}, It looks like a URL, but mime type is ‘text/html’ while I was expecting something with ‘text/plain’ or ‘perl’ in it. I can only understand raw links, sorry.”);

# Did you mean … ?

$t.test(‘Did you mean “all”?’,
        ‘bench: balls say 42’,
        “{$t.our-nick}, ¦balls: «Cannot find this revision (did you mean “all”?)»”);
$t.test(‘Did you mean “HEAD”?’,
        ‘bench: DEAD say 42’,
        “{$t.our-nick}, ¦DEAD: «Cannot find this revision (did you mean “HEAD”?)»”);
$t.test(‘Did you mean some tag?’,
        ‘bench: 2016.55 say 42’,
        “{$t.our-nick}, ¦2016.55: «Cannot find this revision (did you mean “2016.05”?)»”);
$t.test(‘Did you mean some commit?’,
        ‘bench: d2c5694e50 say 42’,
        “{$t.our-nick}, ¦d2c5694: «Cannot find this revision (did you mean “d2c5684”?)»”);
$t.test(‘Only one commit is wrong (did you mean … ?)’,
        ‘bench: 2015.13,2015.12^ say 42’,
        /^ <me($t)>‘, ¦2015.13: «Cannot find this revision (did you mean “2015.12”?)» ¦2015.12^: «’ \d+\.\d+ ‘»’ $/);
$t.test(‘Both commits are wrong (did you mean … ?)’,
        ‘bench: 2015.12^,2015.13,69fecb52eb2 say 42’,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦2015.12^: «’ \d+\.\d+ ‘» ¦2015.13: «Cannot find this revision (did you mean “2015.12”?)» ¦69fecb5: «Cannot find this revision (did you mean “07fecb5”?)»’ $/);

# Extra tests

$t.test(‘last basic query, just in case’, # keep it last in this file
        “{$t.bot-nick}: HEAD say ‘hello’”,
        /^ <me($t)>‘, starting to benchmark the ’ \d+ ‘ given commit’ ‘s’? $/,
        /^ <me($t)>‘, ¦HEAD: «’ \d+\.\d+ ‘»’ $/);

END {
    $t.end;
    sleep 1;
}

done-testing;

# vim: expandtab shiftwidth=4 ft=perl6
