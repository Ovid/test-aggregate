package Test::Aggregate::Nested;

use strict;
use warnings;

use Test::More;
use Test::Aggregate::Base;
use Carp;
use FindBin;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = 'Test::Aggregate::Base';

=head1 NAME

Test::Aggregate::Nested - Aggregate C<*.t> tests to make them run faster.

=head1 VERSION

Version 0.362

=cut

our $VERSION = '0.362';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

    use Test::Aggregate::Nested;

    my $tests = Test::Aggregate::Nested->new( {
        dirs    => $aggregate_test_dir,
        verbose => 1,
    } );
    $tests->run;

=head1 DESCRIPTION

B<ALPHA WARNING>:  this is alpha code.  Conceptually it is superior to
C<Test::Aggregate>, but in reality, it might not be.  We'll see.

This module is almost identical to C<Test::Aggregate> and will in the future
be the preferred way of aggregating tests (until someone comes up with
something better :)

C<Test::Aggregate::Nested> requires a 0.8901 or better of C<Test::More>.  This
is because we use its C<subtest> function.  Currently we C<croak> if this
function is not available.

Because the TAP output is nested, you'll find it much easier to see which
tests result in which output.  For example, consider the following snippet of
TAP.  

    1..2
        1..5
        ok 1 - aggtests/check_plan.t ***** 1
        ok 2 - aggtests/check_plan.t ***** 2
        ok 3 # skip checking plan (aggtests/check_plan.t ***** 3)
        ok 4 - env variables should not hang around
        ok 5 - aggtests/check_plan.t ***** 4
    ok 1 - Tests for aggtests/check_plan.t
        1..1
        ok 1 - subs work!
    ok 2 - Tests for aggtests/subs.t

At the end of each nested test is a summary test line explaining which program
we ran tests for.

C<Test::Aggregate::Nested> asserts a plan equal to the number of test files
aggregated, something which C<Test::Aggregate> could not do.  Because of this,
we no longer export C<Test::More> functions.  If you need additional tests
before or after aggregation, you'll need to run the aggregated tests in a
subtest:

 use Test::More tests => 2;
 use Test::Aggregate::Nested;

 subtest 'Nested tests' => sub {
     Test::Aggregate::Nested->new({ dirs => 'aggtests/' })->run;
 };
 ok $some_other_test;

=head1 CAVEATS

C<Test::Aggregate::Nested> is much cleaner than C<Test::Aggregate>, so I don't
support the C<dump> argument.  If this is needed, let me know and I'll see
about fixing this.

The "variable will not stay shared" warnings from C<Test::Aggregate> (see its
CAVEATS section) are no longer applicable.

=cut

my $REINIT_FINDBIN = FindBin->can(q/again/) || sub {};

sub new {
    my ( $class, $arg_for ) = @_;
    if ( $arg_for->{dump} ) {
        require Carp;
        carp("Dump files are not supported under Test::Aggregate::Nested.");
    }
    unless ( Test::More->can('subtest') ) {
        my $tm_version = Test::More->VERSION;
        croak(<<"        END");
Test::More version $tm_version does not support nested TAP.
Please upgrade to version 0.8901 or newer to use Test::Aggregate::Nested.
        END
    }
    $class->SUPER::new($arg_for);
}

sub run {
    my $self = shift;

    my %test_phase;
    foreach my $attr ( $self->_code_attributes ) {
        my $method = "_$attr";
        $test_phase{$attr} = $self->$method || sub { };
    }

    my @tests = $self->_get_tests;

    my ( $current, $total ) = ( 0, scalar @tests );
    plan tests => $total;
    $test_phase{startup}->();
    for my $test (@tests) {
        $current++;
        no warnings 'uninitialized';
        local %ENV = %ENV;
        local $/   = $/;
        local @INC = @INC;
        local $_   = $_;
        local $|   = $|;
        local %SIG = %SIG;
        local $@;
        use warnings 'uninitialized';

        # restrict this scope as much as possible
        local $0 = $test;
        $test_phase{setup}->();
        $REINIT_FINDBIN->() if $self->_findbin;
        my $package = $self->_get_package($test);
        if ( $self->_verbose ) {
            Test::More::diag("Running tests for $test ($current out of $total)");
        }
        eval <<"        END";
        package $package;
        Test::Aggregate::Nested::subtest("Tests for $test", sub { do \$test });
        END
        diag $@ if $@;
        $test_phase{teardown}->();
    }
    $test_phase{shutdown}->();
}

sub run_this_test_program { }

1;

__END__

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-aggregate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Aggregate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Aggregate

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Aggregate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Aggregate>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Aggregate>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Aggregate>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to mauzo (L<http://use.perl.org/~mauzo/> for helping me find the
'skip_all' bug.

Thanks to Johan Lindström for pointing me to Apache::Registry.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
