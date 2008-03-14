#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;
use Test::More;

my $tests = Test::Aggregate->new(
    {
        dirs     => 'aggtests',
        matching => qr/subs/,
    }
);
$tests->run;
my $tests_run = Test::Builder->new->current_test;
is $tests_run, 2,
  '... and we should only run as many tests as are in the matching tests';
