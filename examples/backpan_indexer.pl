#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';

use blib;
use Data::Dumper;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl qw(:easy);


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Minutely control the environment
{
my %pass_through = map { $_, 1 } qw( DISPLAY USER HOME PWD );

foreach my $key ( keys %ENV ) 
	{ 
	delete $ENV{$key} unless exists $pass_through{$key} 
	}

$ENV{AUTOMATED_TESTING}++;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The set up
my $run_dir = dirname( $0 );

Log::Log4perl->init_and_watch( 
	catfile( $run_dir, 'backpan_indexer.log4perl' ), 
	30 
	);

my $Config = get_config( $run_dir );

setup_dirs( $Config );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Load classes and check that they do the right thing

my $queue_class = $Config->queue_class || __PACKAGE__ . "::Queue";
eval "require $queue_class" or die "$@\n";
die "Interface class [$queue_class] does not implement get_queue()" 
	unless $queue_class->can( 'get_queue' );

my $dispatcher_class = $Config->dispatcher_class || __PACKAGE__ . "::Dispatch::Parallel";
eval "require $dispatcher_class" or die "$@\n";
die "Dispatcher class [$dispatcher_class] does not implement get_dispatcher()" 
	unless $dispatcher_class->can( 'get_dispatcher' );

my $interface_class = $Config->interface_class || __PACKAGE__ . "::Interface::Tk";
eval "require $interface_class" or die "$@\n";
die "Interface class [$interface_class] does not implement do_interface()" 
	unless $interface_class->can( 'do_interface' );

my $worker_class = $Config->worker || __PACKAGE__ . "::Worker";
eval "require $worker_class" or die "$@\n";
die "Interface class [$worker_class] does not implement get_task()" 
	unless $interface_class->can( 'get_task' );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Figure out what to index
my $dists = $queue_class->get_queue( $Config );
die "get_queue did not return an array reference\n"
	unless ref $dists eq ref [];
DEBUG( "Dists to process are\n\t", join "\n\t", @$dists );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The meat of the issue
INFO( "Run started - " . @$dists . " dists to process" );

my $Vars = { 
	queue      => $dists,
	};

$dispatcher_class->get_dispatcher( $Config, $Vars );
#print Dumper( $Vars );
die "Dispatcher class [$dispatcher_class] did not set a dispatcher key\n"
	unless exists $Vars->{dispatcher};

exit;

$interface_class->do_interface( $Vars );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
sub get_config
	{
	require ConfigReader::Simple;

	my $run_dir = shift;
	
	my $conf    = catfile( $run_dir, 'backpan_indexer.config' );
	DEBUG( "Run dir is $run_dir; Conf file is $conf" );
	
	my $Config = ConfigReader::Simple->new( $conf,
		[ qw(temp_dir backpan_dir report_dir alarm 
			copy_bad_dists retry_errors indexer_class) ]
		);
		
	FATAL( "Could not read config!" ) unless ref $Config;


	my $UUID = do { 
		require Data::UUID;
		my $ug = Data::UUID->new; 
		my $uuid = $ug->create;
		$ug->to_string( $uuid );
		};
	
	$Config->set( 'UUID', $UUID );
	
	$conf;
	}


sub setup_dirs
	{
	my $Config = shift;
	
	my $cwd = cwd();
	chdir $Config->temp_dir;
	
	my $yml_dir       = catfile( $Config->report_dir, "meta"        );
	my $yml_error_dir = catfile( $Config->report_dir, "meta-errors" );
	
	DEBUG( "Value of retry is " . $Config->retry_errors );
	DEBUG( "Value of copy_bad_dists is " . $Config->copy_bad_dists );
	
	if( $Config->retry_errors )
		{
		my $glob = catfile( $yml_error_dir, "*.yml" );
		$glob =~ s/ /\\ /g;
	
		unlink glob( $glob );
		}
		
	mkdir $yml_dir,       0755 unless -d $yml_dir;
	mkdir $yml_error_dir, 0755 unless -d $yml_error_dir;
	
	chdir $cwd;
	}