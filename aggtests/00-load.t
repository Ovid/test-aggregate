#!perl 

use Test::More tests => 3;

use lib 't/lib';

BEGIN {
    use_ok('Test::Aggregate')       or die;
    use_ok('Slow::Loading::Module') or die;
}

diag("Testing Test::Aggregate $Test::Aggregate::VERSION, Perl $], $^X");

ok !exists $ENV{aggregated_current_script},
  'env variables should not hang around';
$ENV{aggregated_current_script} = $0;
