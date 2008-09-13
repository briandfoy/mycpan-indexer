#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';

use blib;
use Cwd qw(cwd);
use Data::Dumper;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl qw(:easy);


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Minutely control the environment
{
my %pass_through = map { $_, 1 } qw( DISPLAY USER HOME PWD TERM);

foreach my $key ( keys %ENV ) 
	{ 
	#delete $ENV{$key} unless exists $pass_through{$key} 
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

{
my @components = (
	[ qw( queue_class      MyCPAN::Indexer::Queue             get_queue      ) ],
	[ qw( dispatcher_class MyCPAN::Indexer::Parallel          get_dispatcher ) ],
	[ qw( interface_class  MyCPAN::Indexer::Interface::Curses do_interface   ) ],
	[ qw( reporter_class   MyCPAN::Indexer::Reporter::AsYAML  get_reporter   ) ],
	[ qw( worker_class     MyCPAN::Indexer::Worker            get_task       ) ],
	);

foreach my $tuple ( @components )
	{
	my( $directive, $default_class, $method ) = @$tuple;
	
	my $class = $Config->get( $directive) || $default_class;
	
	eval "require $class" or die "$@\n";
	die "$directive [$queue_class] does not implement $method()" 
		unless $class->can( $method );
	}
	
}

my $Notes = { 
	config     => $Config,
	UUID       => get_uuid(),
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Figure out what to index
$queue_class->get_queue( $Notes );
die "get_queue did set queue to an array reference\n"
	unless ref $Notes->{queue} eq ref [];
DEBUG( "Dists to process are\n\t", join "\n\t", @{ $Notes->{queue} } );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The meat of the issue
INFO( "Run started - " . @{ $Notes->{queue} } . " dists to process" );

$worker_class->get_task( $Notes );

die "get_task is not a code ref" unless 
	ref $Notes->{child_task} eq ref sub {};
	
$dispatcher_class->get_dispatcher( $Notes );
die "Dispatcher class [$dispatcher_class] did not set a dispatcher key\n"
	unless exists $Notes->{dispatcher};

$interface_class->do_interface( $Notes );

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
	
	$Config;
	}

sub setup_dirs
	{
	my $Config = shift;
	
	my $cwd = cwd();
	
	mkdir $Config->temp_dir unless -d $Config->temp_dir;
	chdir $Config->temp_dir or 
		die "Could not change to [" . $Config->temp_dir . "]: $!\n";
	
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
	
sub get_uuid
	{
	my $UUID = do { 
		require Data::UUID;
		my $ug = Data::UUID->new; 
		my $uuid = $ug->create;
		$ug->to_string( $uuid );
		};
	}