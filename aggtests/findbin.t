#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin;
use File::Spec::Functions qw/rel2abs catfile/;

is(rel2abs(catfile($FindBin::Bin, 'findbin.t')), rel2abs($0), 'findbin is reinitialized for every test');
