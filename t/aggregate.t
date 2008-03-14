#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;
use Test::More;

my $dump = 'dump.t';
my $tests = Test::Aggregate->new(
    {
        verbose       => 1,
        dump          => $dump,
        shuffle       => 1,
        dirs          => 'aggtests',
        set_filenames => 1,
    }
);
$tests->run;

ok -f $dump, '... and we should have written out a dump file';
unlink $dump or die "Cannot unlink ($dump): $!";
