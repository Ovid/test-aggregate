#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my $tests = Test::Aggregate->new(
    {
        dirs     => 'aggtests',
        matching => qr/subs/,
    }
);
$tests->run;
my $tests_run = Test::Builder->new->current_test;
is $tests_run, 1,
  '... and we should only run as many tests as are in the matching tests';
