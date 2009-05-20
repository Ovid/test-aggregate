#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::Aggregate;

my ( $startup, $shutdown ) = ( 0, 0 );
my ( $setup,   $teardown ) = ( 0, 0 );

$SIG{__WARN__} = sub {
    my $warning = shift;
    if ( $warning =~ m{Can't locate Data/Dump/Streamer\.pm in \@INC} ) {  #'
        return;
    }
    CORE::warn($warning);
};

my $dump = 'dump.t';

my $tests = Test::Aggregate->new(
    {
        dirs     => 'aggtests',
        findbin  => 1,
        startup  => sub { $startup++ },
        shutdown => sub { $shutdown++ },
        setup    => sub { $setup++ },
        teardown => sub { $teardown++ },
        dump     => $dump,
    }
);
$tests->run;
is $startup,  1, 'Startup should be called once';
is $shutdown, 1, '... as should shutdown';
is $setup,    5, 'Setup should be called once for each test program';
is $teardown, 5, '... as should teardown';
unlink $dump or warn "Cannot unlink ($dump): $!";
done_testing() if __PACKAGE__->can('done_testing');
