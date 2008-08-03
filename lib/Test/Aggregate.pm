package Test::Aggregate;

use warnings;
use strict;

use Test::Builder::Module;
use Test::More;
use Carp 'croak';

use File::Find;

use vars qw(@ISA @EXPORT $VERSION);
@ISA    = qw(Test::Builder::Module);
@EXPORT = @Test::More::EXPORT;

BEGIN { $ENV{TEST_AGGREGATE} = 1 };

END {   # for VMS
    delete $ENV{TEST_AGGREGATE};
}

# controls whether or not we show individual test program pass/fail
my %VERBOSE = (
    none     => 0,
    failures => 1,
    all      => 2,
);

=head1 NAME

Test::Aggregate - Aggregate C<*.t> tests to make them run faster.

=head1 VERSION

Version 0.31

=cut

$VERSION = '0.31';

=head1 SYNOPSIS

    use Test::Aggregate;

    my $tests = Test::Aggregate->new( {
        dirs => $aggregate_test_dir,
    } );
    $tests->run;

=head1 DESCRIPTION

B<WARNING>:  this is ALPHA code.  The interface is not guaranteed to be
stable.

A common problem with many test suites is that they can take a long time to
run.  The longer they run, the less likely you are to run the tests.  This
module borrows a trick from C<Apache::Registry> to load up your tests at once,
create a separate package for each test and wraps each package in a method
named C<run_the_tests>.  This allows us to load perl only once and related
modules only once.  If you have modules which are expensive to load, this can
dramatically speed up a test suite.

=head1 USAGE

Create a separate directory for your tests.  This should not be a subdirectory
of your regular test directory.  Write a small driver program and put it in
your regular test directory (C<t/> is the standard):

 use Test::Aggregate;
 my $other_test_dir = 'aggregate_tests';
 my $tests = Test::Aggregate->new( {
    dirs => $other_test_dir
 });
 $tests->run;

Take your simplest tests and move them, one by one, into the new test
directory and keep running the C<Test::Aggregate> program.  You'll find some
tests will not run in a shared environment like this.  You can either fix the
tests or simply leave them in your regular test directory.  See how this
distribution's tests are organized for an example.

Some tests cannot run in an aggregate environment.  These may include
test for this with the C<< $ENV{TEST_AGGREGATE} >> variable:

 package Some::Package;

 BEGIN {
     die __PACKAGE__ ." cannot run in aggregated tests"
       if $ENV{TEST_AGGREGATE};
 }

=head1 METHODS

=head2 C<new>
 
 my $tests = Test::Aggregate->new(
     {
         dirs            => 'aggtests',
         verbose         => 1,            # optional, but recommended
         dump            => 'dump.t',     # optional
         shuffle         => 1,            # optional
         matching        => qr/customer/, # optional
         set_filenames   => 1,            # optional
         tidy            => 1,            # optional and experimental
         check_plan      => 1,            # optional and experimental
         test_nowarnings => 0,            # optional and experimental
     }
 );
 
Creates a new C<Test::Aggregate> instance.  Accepts a hashref with the
following keys:

=over 4

=item * C<dirs> (mandatory)

The directories to look in for the aggregated tests.  This may be a scalar
value of a single directory or an array refernce of multiple directories.

=item * C<verbose> (optional, but strongly recommended)

If set with a true value, each test programs success or failure will be
indicated with a diagnostic output.  The output below means that
C<aggtests/slow_load.t> was an aggregated test which failed.  This means it's
much easier to determine which aggregated tests are causing problems.

 t/aggregate.........2/? 
 #     ok - aggtests/boilerplate.t
 #     ok - aggtests/00-load.t
 # not ok - aggtests/subs.t
 #     ok - aggtests/slow_load.t
 t/aggregate.........ok
 t/pod-coverage......ok
 t/pod...............ok

Note that three possible values are allowed for C<verbose>:

=over 4

=item * C<0> (default)

No individual test program success or failure will be displayed.

=item * C<1>

Only failing test programs will have their failure status shown.

=item * C<2>

All test programs will have their success/failure shown.

=back

=item * C<dump> (optional)

You may list the name of a file to dump the aggregated tests to.  This is
useful if you have test failures and need to debug why the tests failed.

=item * C<shuffle> (optional)

Ordinarily, the tests are sorted by name and run in that order. This allows
you to run them in any order.

=item * C<matching> (optional)

If supplied with a regular expression (requires the C<qr> operator), will only
run tests whose filename matches the regular expression.

=item * C<set_filenames> (optional)

If supplied with a true value, this will cause the following to be added for
each test:

  local $0 = $test_filename;

Tests which depend on the value of $0 can often be made to work with this.

=item * C<tidy>

If supplied a true value, attempts to run C<Perl::Tidy> on the source code.
This is a no-op if C<Perl::Tidy> cannot be loaded.  This option is
C<experimental>.  Plus, if your tests are terribly convoluted, this could be
slow and possibly buggy.

If the value of this argument is the name of a file, assumes that this file is
a C<.perltidyrc> file.

=item * C<check_plan>

If set to a true value, this will force C<Test::Aggregate> to attempt to
verify that any test which set a plan actually ran the correct number of
tests.  The code is rather tricky, so this is experimental.

=item * C<test_nowarnings>

Disables C<Test::NoWarnings> (fails if the module cannot be loaded).  This is
often used in conjunction with C<check_plan> to subtract the extra test added
by this module.

This is experimental and somewhat problematic.  Let me know if there are any
problems.

=back

=head2 C<run>

 $tests->run;

Attempts to aggregate and run all tests listed in the directories specified in
the constructor.

=cut

sub _code_attributes {
    qw/
        setup
        teardown
        startup
        shutdown
    /;
}

sub new {
    my ( $class, $arg_for ) = @_;

    unless ( exists $arg_for->{dirs} ) {
        Test::More::BAIL_OUT("You must supply 'dirs'");
    }
        
    $arg_for->{test_nowarnings} = 1 unless exists $arg_for->{test_nowarnings};
    my $dirs = delete $arg_for->{dirs};
    $dirs = [$dirs] if 'ARRAY' ne ref $dirs;

    my $matching = qr//;
    if ( $arg_for->{matching} ) {
        $matching = delete $arg_for->{matching};
        unless ( 'Regexp' eq ref $matching ) {
            croak("Argument for 'matching' must be a pre-compiled regex");
        }
    }

    my $has_code_attributes;
    foreach my $attribute ( $class->_code_attributes ) {
        if ( my $ref = $arg_for->{$attribute} ) {
            if ( 'CODE' ne ref $ref ) {
                croak("Attribute ($attribute) must be a code reference");
            }
            else {
                $has_code_attributes++;
            }
        }
    }

    my $self = bless {
        dirs            => $dirs,
        matching        => $matching,
        _no_streamer    => 0,
        _packages       => [],
    } => $class;
    $self->{$_} = delete $arg_for->{$_} foreach (
        qw/
        dump
        set_filenames
        shuffle
        verbose
        tidy
        check_plan
        test_nowarnings
        /,
        $class->_code_attributes
    );

    if ( my @keys = keys %$arg_for ) {
        local $" = ', ';
        croak("Unknown keys to &new:  (@keys)");
    }

    if ($has_code_attributes) {
        eval "use Data::Dump::Streamer";
        if ( my $error = $@ ) {
            $self->{_no_streamer} = 1;
            if ( my $dump = $self->_dump ) {
                warn <<"                END_WARNING";
Dump file ($dump) cannot be generated.  A code attributes was requested but
we cannot load Data::Dump::Streamer:  $error.
                END_WARNING
                $self->{dump} = '';
            }
        }
    }

    return $self;
}

# set from user data

sub _check_plan      { shift->{check_plan} || 0 }
sub _dump            { shift->{dump} || '' }
sub _should_shuffle  { shift->{shuffle} }
sub _matching        { shift->{matching} }
sub _set_filenames   { shift->{set_filenames} }
sub _dirs            { @{ shift->{dirs} } }
sub _startup         { shift->{startup} }
sub _shutdown        { shift->{shutdown} }
sub _setup           { shift->{setup} }
sub _teardown        { shift->{teardown} }
sub _tidy            { shift->{tidy} }
sub _test_nowarnings { shift->{test_nowarnings} }

sub _verbose        {
    my $self = shift;
    $self->{verbose} ? $self->{verbose} : 0;
}

# set from internal data
sub _no_streamer    { shift->{_no_streamer} }
sub _packages       { @{ shift->{_packages} } }

sub _get_tests {
    my $self = shift;
    my @tests;
    my $matching = $self->_matching;
    find( {
            no_chdir => 1,
            wanted   => sub {
                push @tests => $File::Find::name if /\.t\z/ && /$matching/;
            }
    }, $self->_dirs );
    
    if ( $self->_should_shuffle ) {
        $self->_shuffle(@tests);
    }
    else {
        @tests = sort @tests;
    }
    return @tests;
}

sub _shuffle {
    my $self = shift;

    # Fisher-Yates shuffle
    my $i = @_;
    while ($i) {
        my $j = rand $i--;
        @_[ $i, $j ] = @_[ $j, $i ];
    }
    return;
}

sub run {
    my $self  = shift;

    my $code = $self->_build_aggregate_code;

    my $dump = $self->_dump;
    if ( $dump ne '' ) {
        local *FH;
        open FH, "> $dump" or die "Could not open ($dump) for writing: $!";
        print FH $code;
        close FH;
    }
    eval $code;
    if ( my $error = $@ ) {
        croak("Could not run tests: $@");
    }

    $self->_startup->() if $self->_startup;
    my $builder = Test::Builder->new;
    foreach my $data ($self->_packages) {
        my ( $test, $package ) = @$data;
        Test::More::diag("******** running tests for $test ********")
          if $ENV{TEST_VERBOSE};
        $self->_setup->() if $self->_setup;
        eval { $package->run_the_tests };
        if ( my $error = $@ ) {
            Test::More::ok( 0, "Error running ($test):  $error" );
        }

        # XXX this should be fine since these keys are not actually used
        # internally.
        $builder->{XXX_test_failed}       = 0;
        $builder->{TEST_MOST_test_failed} = 0;
        $self->_teardown->() if $self->_teardown;
    }
    $self->_shutdown->() if $self->_shutdown;
}

sub _build_aggregate_code {
    my $self = shift;
    my $code = $self->_test_builder_override;

    my ( $startup,  $startup_code )  = $self->_as_code('startup');
    my ( $shutdown, $shutdown_code ) = $self->_as_code('shutdown');
    my ( $setup,    $setup_code )    = $self->_as_code('setup');
    my ( $teardown, $teardown_code ) = $self->_as_code('teardown');
    my $verbose = $self->_verbose;

    $code .= <<"    END_CODE";
$startup_code
$shutdown_code
$setup_code
$teardown_code
my \$LAST_TEST_NUM = 0;
    END_CODE
    
    my @packages;
    my $separator = '#' x 20;
    
    my $test_packages = '';

    my $dump = $self->_dump;

    $code .= <<"    END_CODE";
if ( __FILE__ eq '$dump' ) {
    package Test::Aggregate; # ;)
    my \$builder = Test::Builder->new;
    END_CODE

    if ( $startup ) {
        $code .= "    $startup->() if __FILE__ eq '$dump';\n";
    }
    foreach my $test ($self->_get_tests) {
        my $test_code = $self->_slurp($test);

        # get rid of hashbangs as Perl::Tidy gets all huffy-like and we
        # disregard them anyway.
        $test_code =~ s/\A#![^\n]+//gm;

        # Strip __END__ and __DATA__ if there's nothing after it.
        # XXX leaving this out for now as I'm unsure if it's worth it.
        #$test_code =~ s/\n__(?:DATA|END)__\n$//s;

        if ( $test_code =~ /^(__(?:DATA|END)__)/m ) {
            Test::More::BAIL_OUT("Test $test not allowed to have $1 token");
        }
        if ( $test_code =~ /skip_all/m ) {
            warn
              "Found possible 'skip_all'.  This can cause test suites to abort";
        }
        my $package   = $self->_get_package($test);
        push @{ $self->{_packages} } => [ $test, $package ];
        if ( $setup ) {
            $code .= "    $setup->('$test');\n";
        }
        $code .= <<"        END_CODE";
    Test::More::diag("******** running tests for $test ********") if \$ENV{TEST_VERBOSE};
    eval { $package->run_the_tests };
    if ( my \$error = \$@ ) {
        Test::More::ok( 0, "Error running ($test):  \$error" );
        # XXX this should be fine since these keys are not actually used
        # internally.
        \$builder->{XXX_test_failed}       = 0;
        \$builder->{TEST_MOST_test_failed} = 0;
    }
        END_CODE
        if ( $teardown ) {
            $code .= "    $teardown->('$test');\n";
        }
        $code .= "\n";

        my $set_filenames = $self->_set_filenames
            ? "local \$0 = '$test';"
            : '';
        my $see_if_tests_passed = $verbose ? <<"        END_CODE" : '';
{
    my \$builder = Test::Builder->new;   # singleton
    my \$tests   = \$builder->current_test;
    my \$failed = 0;
    my \@summary = \$builder->summary;
    foreach my \$passed ( \@summary[\$LAST_TEST_NUM .. \$tests - 1] ) {
        if ( not \$passed ) {
            \$failed = 1;
            last;
        }
    }
    my \$ok = \$failed ? "not ok - $test" : "    ok - $test";
    if ( \$failed or $verbose == $VERBOSE{all} ) {
        Test::More::diag(\$ok);
    }
    \$LAST_TEST_NUM = \$tests;
}
        END_CODE
        $test_packages .= <<"        END_CODE";
{
$separator beginning of $test $separator
package $package;
sub run_the_tests {
\$FILE_FOR{$package} = '$test';
$set_filenames
$test_code
$see_if_tests_passed
}
$separator end of $test $separator
}
        END_CODE
    }
    if ( $shutdown ) {
        $code .= "    $shutdown->() if __FILE__ eq '$dump';\n";
    }

    $code .= "}\n$test_packages";
    if ( my $tidy = $self->_tidy ) {
        eval "use Perl::Tidy";
        my $error = $@;
        my $dump = $self->_dump;
        if ( $error && $dump ) {
            warn "Cannot tidy dumped code:  $error";
        } 
        elsif ( !$error ) {
            my @output;
            my @tidyrc = -f $tidy
                ? ( perltidyrc => $tidy )
                : ();
            Perl::Tidy::perltidy(
                source      => \$code,
                destination => \@output,
                @tidyrc,
            );
            $code = join '' => @output;
        }
    }
    return $code;
}

sub _as_code {
    my ( $self, $name ) = @_;
    my $method   = "_$name";
    return ( '', '' ) if $self->_no_streamer;
    my $code     = $self->$method || return ( '', '' );
    $code = Data::Dump::Streamer::Dump($code)->Indent(0)->Out;
    my $sub_name = "\$TEST_AGGREGATE_\U$name";
    $code =~ s/\$CODE1/$sub_name/;
    return ( $sub_name, <<"    END_CODE" );
my $sub_name;
{
$code
}
    END_CODE
}

sub _slurp {
    my ( $class, $file ) = @_;
    local *FH;
    open FH, "< $file" or die "Cannot read ($file): $!";
    return do { local $/; <FH> };
}

sub _get_package {
    my ( $class, $file ) = @_;
    $file =~ s/\W//g;
    return $file;
}

sub _test_builder_override {
    my $self = shift;

    my $check_plan              = $self->_check_plan;

    my $disable_test_nowarnings = '';
    if ( !$self->_test_nowarnings ) {
        $disable_test_nowarnings = <<'        END_CODE';
# Look ma, no import!
BEGIN {
    require Test::NoWarnings;
    no warnings 'redefine';
    *Test::NoWarnings::had_no_warnings = sub { };
    *Test::NoWarnings::import = sub {
        my $callpack = caller();
        if ( $PLAN_FOR{$callpack} ) {
            $PLAN_FOR{$callpack}--;
        }
        $TEST_NOWARNINGS_LOADED{$callpack} = 1;
    };
}
        END_CODE
    }

    my $code = <<'    END_CODE';
my %PLAN_FOR;
my %TESTS_RUN;
my %FILE_FOR;
my %TEST_NOWARNINGS_LOADED;
    END_CODE
    $code .= <<"    END_CODE";
$disable_test_nowarnings
    END_CODE
    $code .= <<'    END_CODE';
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
    END_CODE
    
    $code .= <<"    END_CODE";
        return unless '$check_plan';
    END_CODE

    $code .= <<'    END_CODE';
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
    END_CODE
    $code .= <<"    END_CODE";
        if ( $check_plan ) {
    END_CODE
    $code .= <<'    END_CODE';
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
    END_CODE
    return $code;
}

=head1 SETUP/TEARDOWN

Since C<BEGIN> and C<END> blocks are for the entire aggregated tests and not
for each test program (see C<CAVEATS>), you might find that you need to have
setup/teardown functions for tests.  These are useful if you need to setup
connections to test databases, clear out temp files, or any of a variety of
tasks that your test suite might require.  Here's a somewhat useless example,
pulled from our tests:

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 
 use lib 'lib', 't/lib';
 use Test::Aggregate;
 use Test::More;
 
 my $dump = 'dump.t';
 
 my ( $startup, $shutdown ) = ( 0, 0 );
 my ( $setup,   $teardown ) = ( 0, 0 );
 my $tests = Test::Aggregate->new(
     {
         dirs     => 'aggtests',
         dump     => $dump,
         startup  => sub { $startup++ },
         shutdown => sub { $shutdown++ },
         setup    => sub { $setup++ },
         teardown => sub { $teardown++ },
     }
 );
 $tests->run;
 is $startup,  1, 'Startup should be called once';
 is $shutdown, 1, '... as should shutdown';
 is $setup,    4, 'Setup should be called once for each test program';
 is $teardown, 4, '... as should teardown';

Note that you can still dump these to a dump file.  This will only work if
C<Data::Dump::Streamer> 1.11 or later is installed.

There are four attributes which can be passed to the constructor, each of
which expects a code reference:

=over 4

=item * C<startup>

 startup => \&connect_to_database,

This function will be called before any of the tests are run.  It is not run
in a BEGIN block.

=item * C<shutdown>

 shutdown => \&clean_up_temp_files,

This function will be called after all of the tests are run.  It will not be
called in an END block.

=item * C<setup>

 setup => sub { 
    # this gets run before each test program.
 },

The setup function will be run before every test program.

=item * C<teardown>

 teardown => sub {
    # this gets run after every test program.
 }

The teardown function gets run after every test program.

=back

=head1 CAVEATS

Not all tests can be included with this technique.  If you have C<Test::Class>
tests, there is no need to run them with this.  Otherwise:

=over 4

=item * C<__END__> and C<__DATA__> tokens.

These won't work and the tests will call BAIL_OUT() if these tokens are seen.

=item * C<BEGIN> and C<END> blocks.

Since all of the tests are aggregated together, C<BEGIN> and C<END> blocks
will be for the scope of the entire set of aggregated tests.  If you need
setup/teardown facilities, see L<SETUP/TEARDOWN>.

=item * Syntax errors

Any syntax errors encountered will cause this program to BAIL_OUT().  This is
why it's recommended that you move your tests into your new directory one at a
time:  it makes it easier to figure out which one has caused the problem.

=item * C<no_plan>

Unfortunately, due to how this works, the plan is always C<no_plan>.  If
C<Test::Builder> implements "deferred plans", we can get a bit more safety.
See
L<http://groups.google.com/group/perl.qa/browse_thread/thread/d58c49db734844f4/cd18996391acc601?#cd18996391acc601>
for more information.  We now have an experimental 'check_plan' attribute to
work around this.

=item * C<Test::NoWarnings>

Great module.  It loves to break aggregated tests since some might have
warnings when others will not.  You can disable it like this:

 my $tests = Test::Aggregate->new(
     dirs    => 'aggtests/',
     startup => sub { $INC{'Test/NoWarnings.pm'} = 1 },
 );

As an alternative, you can also disable it with:

 my $tests = Test::Aggregate->new({
    dirs            => 'aggtests',
    test_nowarnings => 0,
 });

This is needed when you use C<check_plan> and have C<Test::NoWarnings> used.
This is because we do work internally to subtract the extra test added by
C<Test::NoWarnings>.  It's painful and experimental.  Good luck.
    
=item * No 'skip_all' tests, please

Tests which potentially 'skip_all' will cause the aggregate test suite to
abort prematurely.  Do not attempt to aggregate them.  This may be fixed in a
future release.

=item * C<Variable "$x" will not stay shared at (eval ...>

Because each test is wrapped in a method call, any of your subs which access a
variable in an outer scope will likely throw the above warning.  Pass in
arguments explicitly to suppress this.

Instead of:

 my $x = 17;
 sub foo {
     my $y = shift;
     return $y + $x;
 }

Write this:

 my $x = 17;
 sub foo {
     my ( $y, $x ) = @_;
     return $y + $x;
 }

=item * Singletons

Be very careful of code which loads singletons.  Oftimes those singletons in
test suites may be altered for testing purposes, but later attempts to use
those singletons can fail dramatically as they're not expecting the
alterations.  (Your author has painfully learned this lesson with database
connections).

=back

=head1 DEBUGGING AGGREGATE TESTS

Before aggregating tests, make sure that you add tests B<one at a time> to the
aggregated test directory.  Attempting to add many tests to the directory at
once and then experiencing a failure means it will be much harder to track
down which tests caused the failure.

Debugging aggregated tests which fail is a multi-step process.  Let's say the
following fails:

 my $tests = Test::Aggregate->new(
     {
         dump    => 'dump.t',
         shuffle => 1,
         dirs    => 'aggtests',
     }
 );
 $tests->run;

=head2 Manually run the tests

The first step is to manually run all of the tests in the C<aggtests> dir.

 prove -r aggtests/

If the failures appear the same, fix them just like you would fix any other
test failure and then rerun the C<Test::Aggregate> code.

Sometimes this means that a different number of tests run from what the
aggregted tests run.  Look for code which ends the program prematurely, such
as an exception or an C<exit> statement.

=head2 Run a dump file

If this does not fix your problem, create a dump file by passing 
C<< dump => $dumpfile >> to the constructor (as in the above example).  Then
try running this dumpfile directly to attempt to replicate the error:

 prove -r $dumpfile

=head2 Tweaking the dump file

Assuming the error has been replicated, open up the dump file.  The beginning
of the dump file will have some code which overrides some C<Test::Builder>
internals.  After that, you'll see the code which runs the tests.  It will
look similar to this:

 if ( __FILE__ eq 'dump.t' ) {
     Test::More::diag("******** running tests for aggtests/boilerplate.t ********")
        if $ENV{TEST_VERBOSE};
     aggtestsboilerplatet->run_the_tests;

     Test::More::diag("******** running tests for aggtests/subs.t ********")
        if $ENV{TEST_VERBOSE};
     aggtestssubst->run_the_tests;

     Test::More::diag("******** running tests for aggtests/00-load.t ********")
        if $ENV{TEST_VERBOSE};
     aggtests00loadt->run_the_tests;

     Test::More::diag("******** running tests for aggtests/slow_load.t ********")
        if $ENV{TEST_VERBOSE};
     aggtestsslow_loadt->run_the_tests;
 }

You can try to narrow down the problem by commenting out all of the
C<run_the_tests> lines and gradually reintroducing them until you can figure
out which one is actually causing the failure.

=head1 COMMON PITFALLS

=head2 My Tests Through an Exception But Passed Anyway!

This really isn't a C<Test::Aggregate> problem so much as a general Perl
problem.  For each test file, C<Test::Aggregate> wraps the tests in an eval
and checks C<< my $error = $@ >>.  Unfortunately, we sometimes get code like
this:

  $server->ip_address('apple');

And internally, the 'Server' class throws an exception but uses its own evals
in a C<DESTROY> block (or something similar) to trap it.  If the code you call
uses an eval but fails to localize it, it wipes out I<your> eval.  Neat, eh?
Thus, you never get a chance to see the error.  For various reasons, this
tends to impact C<Test::Aggregate> when a C<DESTROY> block is triggered and
calls code which internally uses eval (e.g., C<DBIx::Class>).  You can often
fix this with:

 DESTROY {
    local $@ = $@;  # localize but preserve the value
    my $self = shift;
    # do whatever you want
 }

=head2 C<BEGIN> and C<END> blocks

Remember that since the tests are now being run at once, these blocks will no
longer run on a per-test basis, but will run for the entire aggregated set of
tests.  You may need to examine these individually to determine the problem.
  
=head2 C<CHECK> and C<INIT> blocks.

Sorry, but you can't use these (just as in modperl).  See L<perlmod> for more
information about them and why they won't work.

=head2 C<Test::NoWarnings>

This is a great test module.  When aggregating tests together, however, it can
cause pain as you'll often discover warnings that you never new existed.  For
a quick fix, add this before you attempt to run your tests:

 $INC{'Test/NoWarnings.pm'} = 1;

That will disable C<Test::NoWarnings>, but you'll want to go in later to fix
them.

=head2 Paths

Many tests make assumptions about the paths to files and moving them into a
new test directory can break this.

=head2 C<$0>

Tests which use C<$0> can be problematic as the code is run in an C<eval>
through C<Test::Aggregate> and C<$0> may not match expectations.  This also
means that it can behave differently if run directly from a dump file.

As it turns out, you can assign to C<$0>!  If C<< set_filenames => 1 >> is
passed to the constructor, every test will have the following added to its
package:

 local $0 = $test_file_name;

=head2 Minimal test case

If you cannot solve the problem, feel free to try and create a minimal test
case and send it to me (assuming it's something I can run).

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

1;
