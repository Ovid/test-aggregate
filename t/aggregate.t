#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my $dump = 'dump.t';
my $tests = Test::Aggregate->new(
    {   verbose         => 2,
        dump            => $dump,
        shuffle         => 1,
        dirs            => 'aggtests',
        set_filenames   => 1,
        findbin         => 1,
        check_plan      => 1,
        test_nowarnings => 0,
    }
);
$tests->run;

ok -f $dump, '... and we should have written out a dump file';
#unlink $dump or warn "Cannot unlink ($dump): $!";
