#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';

use blib;
use ConfigReader::Simple;
use Data::Dumper;
use Data::UUID;
use File::Basename;
use File::Find;
use File::Spec::Functions qw(catfile);
use Parallel::ForkManager;
use Log::Log4perl qw(:easy);
use YAML;

require 'tk.pl';
require 'steak.pl';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Choose something to uniquely identify this run
my $UUID = do { 
	my $ug = Data::UUID->new; 
	my $uuid = $ug->create;
	$ug->to_string( $uuid );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Minutely control the environment
my %pass_through = map { $_, 1 } qw( DISPLAY USER HOME PWD );

foreach my $key ( keys %ENV ) 
	{ 
	delete $ENV{$key} unless exists $pass_through{$key} 
	}

$ENV{AUTOMATED_TESTING}++;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The set up
my $run_dir = dirname( $0 );

Log::Log4perl->init_and_watch( 
	catfile( $run_dir, 'backpan_indexer.log4perl' ), 
	30 
	);

my $conf    = catfile( $run_dir, 'backpan_indexer.config' );
DEBUG( "Run dir is $run_dir; Conf file is $conf" );

my $Config = ConfigReader::Simple->new( $conf,
	[ qw(temp_dir backpan_dir report_dir alarm 
		copy_bad_dists retry_errors indexer_class) ]
	);
FATAL "Could not read config!\n" unless ref $Config;

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

my $errors = 0;

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Figure out what to index
my $dists = $queue_class->get_queue( $Config );
die "get_queue did not return an array reference\n"
	unless ref $dists eq ref [];
DEBUG( "Dists to process are\n\t", join "\n\t", @$dists );

exit;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The meat of the issue
INFO( "Run started - " . @$dists . " dists to process" );

my $Vars = { 
	Threads    => 5,
	queue      => $dists,
	UUID       => $UUID,
	child_task => sub { &child_tasks },
	};

$dispatcher_class->get_dispatcher( $Vars );
die "Dispatcher class [$dispatcher_class] did not set \n"
	unless ref $Vars->{foo} eq ref sub {};

exit;

$interface_class->do_interface( $Vars );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
sub child_tasks
	{
	my $dist = shift;
	
	my $basename = check_for_previous_result( $dist );
	return unless $basename;
	
	INFO( "Child [$$] processing $dist\n" );
		
	my $Indexer = $Config->indexer_class || 'MyCPAN::Indexer';
	
	eval "require $Indexer" or die;
	
	unless( chdir $Config->temp_dir )
		{
		ERROR( "Could not change to " . $Config->temp_dir . " : $!\n" );
		exit 255;
		}

	my $out_dir = $yml_error_dir;
	
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm( $Config->alarm || 15 );
	my $info = eval { $Indexer->run( $dist ) };

	unless( defined $info )
		{
		ERROR( "run failed: $@" );
		return;
		}
	elsif( eval { $info->run_info( 'completed' ) } )
		{
		$out_dir = $yml_dir;
		}
	else
		{
		ERROR( "$basename did not complete\n" );
		if( my $bad_dist_dir = $Config->copy_bad_dists )
			{
			my $dist_file = $info->dist_info( 'dist_file' );
			my $basename  = $info->dist_info( 'dist_basename' );
			my $new_name  = File::Spec->catfile( $bad_dist_dir, $basename );
			
			unless( -e $new_name )
				{
				DEBUG( "Copying bad dist" );
				open my($in), "<", $dist_file;
				open my($out), ">", $new_name;
				while( <$in> ) { print { $out } $_ }
				close $in;
				close $out;
				}
			}	
		}
		
	alarm 0;
			
	add_run_info( $info );
	
	my $out_path = catfile( $out_dir, "$basename.yml" );
	
	open my($fh), ">", $out_path or die "Could not open $out_path: $!\n";
	print $fh Dump( $info );
	
	1;
	}
	
sub check_for_previous_result
	{	
	my $dist = shift;
	
	( my $basename = basename( $dist ) ) =~ s/\.(tgz|tar\.gz|zip)$//;
	
	my $yml_path       = catfile( $yml_dir,       "$basename.yml" );
	my $yml_error_path = catfile( $yml_error_dir, "$basename.yml" );
	
	if( my @path = grep { -e } ( $yml_path, $yml_error_path ) )
		{
		DEBUG( "Found run output for $basename in $path[0]. Skipping...\n" );
		return;
		}
		
	return $basename;
	}

sub add_run_info
	{
	my( $info ) = shift;
	
	return unless eval { $info->can( 'set_run_info' ) };
	
	$info->set_run_info( $_, $Config->get( $_ ) ) 
		foreach ( $Config->directives );
	
	$info->set_run_info( 'uuid', $UUID ); 

	$info->set_run_info( 'child_pid',  $$ ); 
	$info->set_run_info( 'parent_pid', getppid ); 

	$info->set_run_info( 'ENV', \%ENV ); 
	
	return 1;
	}