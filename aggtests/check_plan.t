#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 5;

BEGIN { ok 1, "$0 ***** 1" }
END   { ok 1, "$0 ***** 4" }
ok 1, "$0 ***** 2";

SKIP: {
    skip "checking plan ($0 ***** 3)", 1;
    ok 1;
}

ok !exists $ENV{aggregated_current_script},
  'env variables should not hang around';
$ENV{aggregated_current_script} = $0;
