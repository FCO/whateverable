#!/usr/bin/env perl6
BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;
%*ENV<TESTABLE> = 1;

use lib ‘t/lib’;
use Test;
use IRC::Client;
use Testable;

my $t = Testable.new(bot => ‘./Unicodable.p6’);

# Help messages

$t.test(‘help message’,
        “{$t.bot-nick}, helP”,
        “{$t.our-nick}, Just type any unicode character or part of a character name.”
            ~ ‘ Alternatively, you can also provide a code snippet.’
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Unicodable’);

$t.test(‘help message’,
        “{$t.bot-nick},   HElp?  ”,
        “{$t.our-nick}, Just type any unicode character or part of a character name.”
            ~ ‘ Alternatively, you can also provide a code snippet.’
            ~ ‘ # See wiki for more examples: https://github.com/perl6/whateverable/wiki/Unicodable’);

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
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Unicodable”);

$t.test(‘source link’,
        “{$t.bot-nick}:   wiki? ”,
        “{$t.our-nick}, https://github.com/perl6/whateverable/wiki/Unicodable”);

# Basics

$t.test(‘basic “nick:” query’,
        “{$t.bot-nick}: 🦋”,
        “{$t.our-nick}, U+1F98B BUTTERFLY [So] (🦋)”);

$t.test(‘basic “nick,” query’,
        “{$t.bot-nick}, 🍋”,
        “{$t.our-nick}, U+1F34B LEMON [So] (🍋)”);

$t.test(‘“u:” shortcut’,
        ‘u: ⮟’,
        “{$t.our-nick}, U+2B9F BLACK DOWNWARDS EQUILATERAL ARROWHEAD [So] (⮟)”);

$t.test(‘Two symbols’,
        ‘u: ⢯🁿’,
        “{$t.our-nick}, U+28AF BRAILLE PATTERN DOTS-123468 [So] (⢯)”,
        “{$t.our-nick}, U+1F07F DOMINO TILE VERTICAL-04-00 [So] (🁿)”);

$t.test(‘Three symbols’,
        ‘u: ⇲ ⮬’,
        “{$t.our-nick}, U+21F2 SOUTH EAST ARROW TO CORNER [So] (⇲)”,
        “{$t.our-nick}, U+0020 SPACE [Zs] ( )”,
        “{$t.our-nick}, U+2BAC BLACK CURVED LEFTWARDS AND UPWARDS ARROW [So] (⮬)”);

$t.test(‘More than three uploaded’,
        ‘u: ㈰🁍⩟⏛℧’,
        “{$t.our-nick}, U+3230 PARENTHESIZED IDEOGRAPH SUN [So] (㈰)”,
        “{$t.our-nick}, U+1F04D DOMINO TILE HORIZONTAL-04-00 [So] (🁍)”,
        “{$t.our-nick}, 5 characters in total: https://whatever.able/fakeupload”);

$t.test(‘Search by words’,
        ‘u: POO PILE’,
        “{$t.our-nick}, U+1F4A9 PILE OF POO [So] (💩)”);

$t.test(‘Search by words’,
        ‘u: PILE POO  ’,
        “{$t.our-nick}, U+1F4A9 PILE OF POO [So] (💩)”);

$t.test(‘Search by general property and words’,
        ‘u: Nd two BoL -’,
        “{$t.our-nick}, U+1D7EE MATHEMATICAL SANS-SERIF BOLD DIGIT TWO [Nd] (𝟮)”);

$t.test(‘Search by word (numeric)’,
        ‘u: 125678’,
        “{$t.our-nick}, U+28F3 BRAILLE PATTERN DOTS-125678 [So] (⣳)”);

$t.test(‘Search by codepoint number’,
        ‘u: Ü+1F40D u±1f40F 𝟎ẍ1F40B’,
        “{$t.our-nick}, U+1F40D SNAKE [So] (🐍)”,
        “{$t.our-nick}, U+1F40F RAM [So] (🐏)”,
        “{$t.our-nick}, U+1F40B WHALE [So] (🐋)”);

$t.test(‘Search using the code block’,
        ‘u: { .uniname.uc eq ‘BUTTERFLY’ }’,
        “{$t.our-nick}, U+1F98B BUTTERFLY [So] (🦋)”);

$t.test(‘Found nothing!’,
        ‘u: sohurbkuraoehu’,
        “{$t.our-nick}, Found nothing!”);

$t.test(‘Some control characters’,
        ‘u: 0x0 0x7 0X7F’,
        “{$t.our-nick}, U+0000 <control-0000> [Cc] (control character)”,
        “{$t.our-nick}, U+0007 <control-0007> [Cc] (control character)”,
        “{$t.our-nick}, U+007F <control-007F> [Cc] (control character)”);

$t.test(‘Some interesting ASCII characters’,
        ｢u: \"<｣,
        “{$t.our-nick}, U+005C REVERSE SOLIDUS [Po] (\)”,
        “{$t.our-nick}, U+0022 QUOTATION MARK [Po] (")”,
        “{$t.our-nick}, U+003C LESS-THAN SIGN [Sm] (<)”);

$t.test(‘Combining characters’,
        ‘u: Xͫ⃝’,
        “{$t.our-nick}, U+0058 LATIN CAPITAL LETTER X [Lu] (X)”,
        “{$t.our-nick}, U+036B COMBINING LATIN SMALL LETTER M [Mn] (◌ͫ)”,
        “{$t.our-nick}, U+20DD COMBINING ENCLOSING CIRCLE [Me] (◌⃝)”);

$t.test(‘Invalid characters’,
        ‘u: 0x11FFFF 0x99999999’,
        “{$t.our-nick}, U+11FFFF <unassigned> [] (unencodable character)”,
        “{$t.our-nick}, U+99999999 (invalid codepoint)”);

# URLs

$t.test(‘fetching code from urls’,
        ‘u: https://gist.githubusercontent.com/AlexDaniel/1892f93da146cb6057e6f3ca38fb1e56/raw/3d007a9ec3782f756054a322e8710656e2e4e7c6/test’,
        “{$t.our-nick}, Successfully fetched the code from the provided URL.”,
        “{$t.our-nick}, U+1F4A9 PILE OF POO [So] (💩)”,
        “{$t.our-nick}, U+0021 EXCLAMATION MARK [Po] (!)”);

$t.test(‘wrong url’,
        ‘u: http://github.org/sntoheausnteoahuseoau’,
        “{$t.our-nick}, It looks like a URL, but for some reason I cannot download it (HTTP status line is 404 Not Found).”);

$t.test(‘wrong mime type’,
        ‘u: https://www.wikipedia.org/’,
        “{$t.our-nick}, It looks like a URL, but mime type is ‘text/html’ while I was expecting something with ‘text/plain’ or ‘perl’ in it. I can only understand raw links, sorry.”);


# Yoleaux replacement

$t.test(‘Answers on ‘.u’ when yoleaux is not around’,
        ‘.u ㊷’,
        /^ <me($t)>‘, U+32B7 CIRCLED NUMBER FORTY TWO [No] (㊷)’ $/);

my $yoleaux = IRC::Client.new(:nick(‘yoleaux’) :host<127.0.0.1> :channels<#whateverable>);
start $yoleaux.run;
sleep 1;

$t.test(‘Yoleaux is back, be silent’,
        ‘.u ㊸’);

$yoleaux.quit;
sleep 1;

$t.test(‘Answers on ‘.u’ when yoleaux is not around again’,
        ‘.u ㊹’,
        /^ <me($t)>‘, U+32B9 CIRCLED NUMBER FORTY FOUR [No] (㊹)’ $/);

# Extra tests

$t.test(‘last basic query, just in case’, # keep it last in this file
        “{$t.bot-nick}: 🐵⨴𝈧”,
        /^ <me($t)>‘, U+1F435 MONKEY FACE [So] (🐵)’ $/,
        /^ <me($t)>‘, U+2A34 MULTIPLICATION SIGN IN LEFT HALF CIRCLE [Sm] (⨴)’ $/,
        /^ <me($t)>‘, U+1D227 GREEK INSTRUMENTAL NOTATION SYMBOL-17 [So] (𝈧)’ $/);

done-testing;
END $t.end;
