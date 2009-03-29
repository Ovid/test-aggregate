use strict;
use warnings;
use Module::Build;

use 5.006;

my $builder = Module::Build->new(
    module_name       => 'Test::Aggregate',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Test/Aggregate.pm',
    build_requires    => {
        'Test::Simple' => 0.74,    # we fail on the common 0.62
        'Test::Most'   => 0.21,,
    },
    requires => {
        'Test::Harness'    => 3.09,
        'Test::NoWarnings' => 0,
        'FindBin'          => 0,
    },
    recommends => {
        'Data::Dump::Streamer' => 1.11,
        'Perl::Tidy'           => 20060614,
    },
    add_to_cleanup     => ['Test-Aggregate-*'],
);

$builder->create_build_script();
