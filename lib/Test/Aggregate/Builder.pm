package Test::Aggregate::Builder;

use strict;
use warnings;

our $VERSION;

=head1 NAME

Test::Aggregate::Builder - Internal overrides for Test::Builder.

=head1 VERSION

Version 0.34_04

=cut

$VERSION = '0.34_04';

=head1 SYNOPSIS

    use Test::Aggregate::Builder;

=head1 DESCRIPTION

B<WARNING>:  This module is for internal use only.  DO NOT USE DIRECTLY.

=cut 

our %PLAN_FOR;
our %TESTS_RUN;
our %FILE_FOR;
our %TEST_NOWARNINGS_LOADED;
our $CHECK_PLAN;

BEGIN { $ENV{TEST_AGGREGATE} = 1 }

END {    # for VMS
    delete $ENV{TEST_AGGREGATE};
}
use Test::Builder;

no warnings 'redefine';

# Need a tailing plan
END {

    # This works because it's a singleton
    my $builder = Test::Builder->new;
    my $tests   = $builder->current_test;
    $builder->_print("1..$tests\n");
}

# The following is done to get around the fact that deferred plans are not
# supported.  Unfortunately, there's no clean way to override this, but this
# allows us to minimize the monkey patching.

# XXX We fully-qualify the sub names because PAUSE won't index what it thinks
# is an attempt to hijack the Test::Builder namespace.

sub Test::Builder::_plan_check {
    my $self = shift;

    # Will this break under threads?
    $self->{Expected_Tests} = $self->{Curr_Test} + 1;
}

sub Test::Builder::no_header { 1 }

# prevent the 'you tried to plan twice' errors
my $plan;
BEGIN { $plan = \&Test::Builder::plan }

our %SKIP_REASON_FOR;

sub Test::Builder::plan {
    delete $_[0]->{Have_Plan};

    if ( 'skip_all' eq ( $_[1] || '' )) {
        my $callpack = caller(1);
        $SKIP_REASON_FOR{$callpack} = $_[2];
        return;
    }

    my $callpack = caller(1);
    if ( 'tests' eq ( $_[1] || '' ) ) {
        $PLAN_FOR{$callpack} = $_[2];
        if ( $TEST_NOWARNINGS_LOADED{$callpack} ) {

            # Test::NoWarnings was loaded before plan() was called, so it
            # didn't have a change to decrement it
            $PLAN_FOR{$callpack}--;
        }
    }
    $plan->(@_);
}

my $ok;
BEGIN { $ok = \&Test::Builder::ok }

sub Test::Builder::ok {
    my $callpack = __check_test_count();
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $ok->(@_);
}

# Called in _ending and prevents the 'you tried to run a test without a
# plan' error.
my $_sanity_check;
BEGIN { $_sanity_check = \&Test::Builder::_sanity_check }

sub Test::Builder::_sanity_check {
    $_[0]->{Have_Plan} = 1;
    $_sanity_check->(@_);
}

my $skip;
BEGIN { $skip = \&Test::Builder::skip }

sub Test::Builder::skip {
    __check_test_count();
    $skip->(@_);
}

# two purposes:  we check the test cout for a package, but we also return the
# package name
sub __check_test_count {
    my $callpack;
    return unless $CHECK_PLAN;
    my $stack_level = 1;
    while ( my ( $package, undef, undef, $subroutine ) = caller($stack_level) ) {
        last if 'Test::Aggregate' eq $package;

        # XXX Because these blocks aren't really subroutines, caller()
        # doesn't report what you expect.
        last
          if $callpack && $subroutine =~ /::(?:BEGIN|END)\z/;
        $callpack = $package;
        $stack_level++;
    }
    {
        no warnings 'uninitialized';
        $TESTS_RUN{$callpack} += 1;
    }
    return $callpack;
}

END {
    if ($CHECK_PLAN) {
        while ( my ( $package, $plan ) = each %PLAN_FOR ) {

            # The following line is needed because it's sometimes the case
            # in larger systems that plans and tests are specified in
            # libraries (and not the test files) which multiple test files
            # use.  As a result, it can be extremely difficult to track
            # this.  We may change this in the future.
            next unless my $file = $FILE_FOR{$package};
            Test::More::is( $TESTS_RUN{$package} || 0,
                $plan || 0, "Test ($file) should have the correct plan" );
        }
    }
}

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

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
