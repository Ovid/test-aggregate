my %PLAN_FOR;
my %TESTS_RUN;
my %FILE_FOR;
my %TEST_NOWARNINGS_LOADED;

{
    BEGIN { $ENV{TEST_AGGREGATE} = 1 };

    END {   # for VMS
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
    # supported.  Unfortunately, there's no clean way to override this, but
    # this allows us to minimize the monkey patching.

    # XXX We fully-qualify the sub names because PAUSE won't index what it
    # thinks is an attempt to hijeck the Test::Builder namespace.

    sub Test::Builder::_plan_check {
        my $self = shift;

        # Will this break under threads?
        $self->{Expected_Tests} = $self->{Curr_Test} + 1;
    }

    sub Test::Builder::no_header { 1 }

    # prevent the 'you tried to plan twice' errors
    my $plan;
    BEGIN { $plan = \&Test::Builder::plan }
    sub Test::Builder::plan {
        delete $_[0]->{Have_Plan};
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

    # Called in _ending and prevents the 'you tried to run a test without a
    # plan' error.
    my $_sanity_check;
    BEGIN { $_sanity_check = \&Test::Builder::_sanity_check }
    sub Test::Builder::_sanity_check {
        $_[0]->{Have_Plan} = 1;
        $_sanity_check->(@_);
    }

    my $ok;
    BEGIN { $ok = \&Test::Builder::ok }
    sub Test::Builder::ok {
        __check_test_count();
        $ok->(@_);
    }

    my $skip;
    BEGIN { $skip = \&Test::Builder::skip }
    sub Test::Builder::skip {
        __check_test_count();
        $skip->(@_);
    }

    sub __check_test_count {
        return unless '0';
        my $callpack;
        my $stack_level = 1;
        while ( my ( $package, $filename, $line, $subroutine )
            = caller($stack_level) )
        {
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
    }

    END {
        if ( 0 ) {
            while ( my ( $package, $plan ) = each %PLAN_FOR ) {

                # The following line is needed because it's sometimes the case
                # in larger systems that plans and tests are specified in
                # libraries (and not the test files) which multiple test files
                # use.  As a result, it can be extremely difficult to track
                # this.  We may change this in the future.
                next unless my $file = $FILE_FOR{$package};
                Test::More::is(
                    $TESTS_RUN{$package} || 0,
                    $plan || 0,
                    "Test ($file) should have the correct plan"
                );
            }
        }
    }
}
my $TEST_AGGREGATE_STARTUP;
{
my ($startup);
$startup=3;
$TEST_AGGREGATE_STARTUP=sub {
  BEGIN {${^WARNING_BITS} = "UUUUUUUUUUUU\005"}
  use strict 'refs';
  $startup++;
};

}

my $TEST_AGGREGATE_SHUTDOWN;
{
my ($shutdown);
$shutdown=0;
$TEST_AGGREGATE_SHUTDOWN=sub {
  BEGIN {${^WARNING_BITS} = "UUUUUUUUUUUU\005"}
  use strict 'refs';
  $shutdown++;
};

}

my $TEST_AGGREGATE_SETUP;
{
my ($setup);
$setup=3;
$TEST_AGGREGATE_SETUP=sub {
  BEGIN {${^WARNING_BITS} = "UUUUUUUUUUUU\005"}
  use strict 'refs';
  $setup++;
};

}

my $TEST_AGGREGATE_TEARDOWN;
{
my ($teardown);
$teardown=0;
$TEST_AGGREGATE_TEARDOWN=sub {
  BEGIN {${^WARNING_BITS} = "UUUUUUUUUUUU\005"}
  use strict 'refs';
  $teardown++;
};

}

my $LAST_TEST_NUM = 0;
if ( __FILE__ eq 'dump.t' ) {
    package Test::Aggregate; # ;)
    my $builder = Test::Builder->new;
    $TEST_AGGREGATE_STARTUP->() if __FILE__ eq 'dump.t';
    $TEST_AGGREGATE_SETUP->('aggtests/00-load.t');
    Test::More::diag("******** running tests for aggtests/00-load.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtests00loadt->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/00-load.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/00-load.t');

    $TEST_AGGREGATE_SETUP->('aggtests/boilerplate.t');
    Test::More::diag("******** running tests for aggtests/boilerplate.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestsboilerplatet->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/boilerplate.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/boilerplate.t');

    $TEST_AGGREGATE_SETUP->('aggtests/check_plan.t');
    Test::More::diag("******** running tests for aggtests/check_plan.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestscheck_plant->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/check_plan.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/check_plan.t');

    $TEST_AGGREGATE_SETUP->('aggtests/slow_load.t');
    Test::More::diag("******** running tests for aggtests/slow_load.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestsslow_loadt->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/slow_load.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/slow_load.t');

    $TEST_AGGREGATE_SETUP->('aggtests/subs.t');
    Test::More::diag("******** running tests for aggtests/subs.t ********") if $ENV{TEST_VERBOSE};
    eval { aggtestssubst->run_the_tests };
    if ( my $error = $@ ) {
        Test::More::ok( 0, "Error running (aggtests/subs.t):  $error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
    }
    $TEST_AGGREGATE_TEARDOWN->('aggtests/subs.t');

    $TEST_AGGREGATE_SHUTDOWN->() if __FILE__ eq 'dump.t';
}
{
#################### beginning of aggtests/00-load.t ####################
package aggtests00loadt;
sub run_the_tests {
$FILE_FOR{aggtests00loadt} = 'aggtests/00-load.t';



use Test::More tests => 2;

use lib 't/lib';

BEGIN {
    use_ok('Test::Aggregate')       or die;
    use_ok('Slow::Loading::Module') or die;
}

diag("Testing Test::Aggregate $Test::Aggregate::VERSION, Perl $], $^X");


}
#################### end of aggtests/00-load.t ####################
}
{
#################### beginning of aggtests/boilerplate.t ####################
package aggtestsboilerplatet;
sub run_the_tests {
$FILE_FOR{aggtestsboilerplatet} = 'aggtests/boilerplate.t';



use strict;
use warnings;
use Test::More tests => 3;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    local *FH;
    open FH, "< $filename"
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <FH>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

module_boilerplate_ok('lib/Test/Aggregate.pm');


}
#################### end of aggtests/boilerplate.t ####################
}
{
#################### beginning of aggtests/check_plan.t ####################
package aggtestscheck_plant;
sub run_the_tests {
$FILE_FOR{aggtestscheck_plant} = 'aggtests/check_plan.t';



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


}
#################### end of aggtests/check_plan.t ####################
}
{
#################### beginning of aggtests/slow_load.t ####################
package aggtestsslow_loadt;
sub run_the_tests {
$FILE_FOR{aggtestsslow_loadt} = 'aggtests/slow_load.t';



use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 1;
use Slow::Loading::Module;
ok 1, 'slow loading module loaded';


}
#################### end of aggtests/slow_load.t ####################
}
{
#################### beginning of aggtests/subs.t ####################
package aggtestssubst;
sub run_the_tests {
$FILE_FOR{aggtestssubst} = 'aggtests/subs.t';



use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 1;
use Slow::Loading::Module;

{
    no warnings;
    my $whee = 'whee!';
    sub whee { return $whee }
}

is whee(), 'whee!', 'subs work!';


}
#################### end of aggtests/subs.t ####################
}
