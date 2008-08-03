#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 4;

BEGIN { ok 1 }
END   { ok 1 }
ok 1;

SKIP: {
    skip 'checking plan', 1;
    ok 1;
}
