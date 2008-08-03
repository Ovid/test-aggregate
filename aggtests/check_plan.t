#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 4;

BEGIN { ok 1, "$0 ***** 1" }
END   { ok 1, "$0 ***** 4" }
ok 1, "$0 ***** 2";

SKIP: {
    skip "checking plan ($0 ***** 3)", 1;
    ok 1;
}
