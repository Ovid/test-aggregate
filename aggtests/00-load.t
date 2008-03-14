#!perl 

use Test::More tests => 2;

use lib 't/lib';

BEGIN {
    use_ok('Test::Aggregate')       or die;
    use_ok('Slow::Loading::Module') or die;
}

diag("Testing Test::Aggregate $Test::Aggregate::VERSION, Perl $], $^X");
