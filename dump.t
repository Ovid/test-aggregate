{
    $ENV{TEST_AGGREGATE} = 1;

    END {   # for VMS
        delete $ENV{TEST_AGGREGATE};
    }
    use Test::Builder;
    use Test::Builder::Module;

    no warnings 'redefine';

    END {

        # This works because it's a singleton
        my $builder = Test::Builder->new;
        my $tests   = $builder->current_test;
        $builder->_print("1..$tests\n");
    }

    sub Test::Builder::_plan_check {
        my $self = shift;

        # Will this break under threads?
        $self->{Expected_Tests} = $self->{Curr_Test} + 1;
    }

    sub Test::Builder::no_header { 1 }

    sub Test::Builder::plan {
        my ( $self, $cmd, $arg ) = @_;

        return unless $cmd;

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        # XXX need to disable the plan check
        #if( $self->{Have_Plan} ) {
        #    $self->croak("You tried to plan twice");
        #}

        if ( $cmd eq 'no_plan' ) {
            $self->no_plan;
        }
        elsif ( $cmd eq 'skip_all' ) {
            return $self->skip_all($arg);
        }
        elsif ( $cmd eq 'tests' ) {
            if ($arg) {
                local $Test::Builder::Level = $Test::Builder::Level + 1;
                return $self->expected_tests($arg);
            }
            elsif ( !defined $arg ) {
                $self->croak("Got an undefined number of tests");
            }
            elsif ( !$arg ) {
                $self->croak("You said to run 0 tests");
            }
        }
        else {
            my @args = grep { defined } ( $cmd, $arg );
            $self->croak("plan() doesn't understand @args");
        }

        return 1;
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
    $TEST_AGGREGATE_STARTUP->();
    $TEST_AGGREGATE_SETUP->('aggtests/00-load.t');
    Test::More::ok(1, "******** running tests for aggtests/00-load.t ********");
    aggtests00loadt->run_the_tests;
    $TEST_AGGREGATE_TEARDOWN->('aggtests/00-load.t');

    $TEST_AGGREGATE_SETUP->('aggtests/boilerplate.t');
    Test::More::ok(1, "******** running tests for aggtests/boilerplate.t ********");
    aggtestsboilerplatet->run_the_tests;
    $TEST_AGGREGATE_TEARDOWN->('aggtests/boilerplate.t');

    $TEST_AGGREGATE_SETUP->('aggtests/slow_load.t');
    Test::More::ok(1, "******** running tests for aggtests/slow_load.t ********");
    aggtestsslow_loadt->run_the_tests;
    $TEST_AGGREGATE_TEARDOWN->('aggtests/slow_load.t');

    $TEST_AGGREGATE_SETUP->('aggtests/subs.t');
    Test::More::ok(1, "******** running tests for aggtests/subs.t ********");
    aggtestssubst->run_the_tests;
    $TEST_AGGREGATE_TEARDOWN->('aggtests/subs.t');

    $TEST_AGGREGATE_SHUTDOWN->();
}
{
#################### beginning of aggtests/00-load.t ####################
package aggtests00loadt;
sub run_the_tests {



use Test::More tests => 2;

use lib 't/lib';

BEGIN {
    use_ok('Test::Aggregate')       or die;
    use_ok('Slow::Loading::Module') or die;
}

diag("Testing Test::Aggregate $Test::Aggregate::VERSION, Perl $], $^X");

{
    my $builder = Test::Builder->new;   # singleton
    my $tests   = $builder->current_test;
    my $failed = 0;
    my @summary = $builder->summary;
    foreach my $passed ( @summary[$LAST_TEST_NUM .. $tests - 1] ) {
        if ( not $passed ) {
            $failed = 1;
            last;
        }
    }
    my $ok = $failed ? "not ok - aggtests/00-load.t" : "    ok - aggtests/00-load.t";
    Test::More::diag($ok) if 0;
    $LAST_TEST_NUM = $tests;
}
}
#################### end of aggtests/00-load.t ####################
}
{
#################### beginning of aggtests/boilerplate.t ####################
package aggtestsboilerplatet;
sub run_the_tests {



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

{
    my $builder = Test::Builder->new;   # singleton
    my $tests   = $builder->current_test;
    my $failed = 0;
    my @summary = $builder->summary;
    foreach my $passed ( @summary[$LAST_TEST_NUM .. $tests - 1] ) {
        if ( not $passed ) {
            $failed = 1;
            last;
        }
    }
    my $ok = $failed ? "not ok - aggtests/boilerplate.t" : "    ok - aggtests/boilerplate.t";
    Test::More::diag($ok) if 0;
    $LAST_TEST_NUM = $tests;
}
}
#################### end of aggtests/boilerplate.t ####################
}
{
#################### beginning of aggtests/slow_load.t ####################
package aggtestsslow_loadt;
sub run_the_tests {



use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 1;
use Slow::Loading::Module;
ok 1, 'slow loading module loaded';

{
    my $builder = Test::Builder->new;   # singleton
    my $tests   = $builder->current_test;
    my $failed = 0;
    my @summary = $builder->summary;
    foreach my $passed ( @summary[$LAST_TEST_NUM .. $tests - 1] ) {
        if ( not $passed ) {
            $failed = 1;
            last;
        }
    }
    my $ok = $failed ? "not ok - aggtests/slow_load.t" : "    ok - aggtests/slow_load.t";
    Test::More::diag($ok) if 0;
    $LAST_TEST_NUM = $tests;
}
}
#################### end of aggtests/slow_load.t ####################
}
{
#################### beginning of aggtests/subs.t ####################
package aggtestssubst;
sub run_the_tests {



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

{
    my $builder = Test::Builder->new;   # singleton
    my $tests   = $builder->current_test;
    my $failed = 0;
    my @summary = $builder->summary;
    foreach my $passed ( @summary[$LAST_TEST_NUM .. $tests - 1] ) {
        if ( not $passed ) {
            $failed = 1;
            last;
        }
    }
    my $ok = $failed ? "not ok - aggtests/subs.t" : "    ok - aggtests/subs.t";
    Test::More::diag($ok) if 0;
    $LAST_TEST_NUM = $tests;
}
}
#################### end of aggtests/subs.t ####################
}
