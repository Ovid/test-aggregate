use Test::Aggregate::Builder;
BEGIN { $Test::Aggregate::Builder::CHECK_PLAN = 0 };
;
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
$Test::Aggregate::Builder::FILE_FOR{aggtests00loadt} = 'aggtests/00-load.t';
local $0 = 'aggtests/00-load.t';
# line 1 "aggtests/00-load.t"


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
$Test::Aggregate::Builder::FILE_FOR{aggtestsboilerplatet} = 'aggtests/boilerplate.t';
local $0 = 'aggtests/boilerplate.t';
# line 1 "aggtests/boilerplate.t"


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
$Test::Aggregate::Builder::FILE_FOR{aggtestscheck_plant} = 'aggtests/check_plan.t';
local $0 = 'aggtests/check_plan.t';
# line 1 "aggtests/check_plan.t"


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


}
#################### end of aggtests/check_plan.t ####################
}
{
#################### beginning of aggtests/slow_load.t ####################
package aggtestsslow_loadt;
sub run_the_tests {
$Test::Aggregate::Builder::FILE_FOR{aggtestsslow_loadt} = 'aggtests/slow_load.t';
local $0 = 'aggtests/slow_load.t';
# line 1 "aggtests/slow_load.t"


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
$Test::Aggregate::Builder::FILE_FOR{aggtestssubst} = 'aggtests/subs.t';
local $0 = 'aggtests/subs.t';
# line 1 "aggtests/subs.t"


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
