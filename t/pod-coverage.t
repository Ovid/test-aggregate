#!perl -T

use strict;
use warnings;
use Test::More;
eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;
pod_coverage_ok( 'Test::Aggregate', { trustme => [ qr/(?:no_header|plan)/ ] } );
