package MyCPAN::App::BackPAN::Indexer;

use strict;
use warnings;
no warnings 'uninitialized';

use vars qw($VERSION);

use Carp;
use Cwd qw(cwd);
use File::Basename;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Getopt::Std;
use Log::Log4perl;

$VERSION = '1.17_09';

$|++;

my $logger = Log::Log4perl->get_logger( 'backpan_indexer' );

__PACKAGE__->run( @ARGV ) unless caller;

#$SIG{__WARN__} = sub { Carp::cluck( @_ ) };

BEGIN {
my $cwd = cwd();

my $report_dir = catfile( $cwd, 'indexer_reports' );

my %Defaults = (
	report_dir            => $report_dir,
	success_report_subdir => catfile( $report_dir, 'success' ),
	error_report_subdir   => catfile( $report_dir, 'errors'  ),
	alarm                 => 15,
	log_file_watch_time   => 30,
	copy_bad_dists        => 0,
	retry_errors          => 1,
	indexer_id            => 'Joe Example <joe@example.com>',
	system_id             => 'an unnamed system',
	indexer_class         => 'MyCPAN::Indexer',
	queue_class           => 'MyCPAN::Indexer::Queue',
	dispatcher_class      => 'MyCPAN::Indexer::Dispatch::Parallel',
	interface_class       => 'MyCPAN::Indexer::Interface::Text',
	worker_class          => 'MyCPAN::Indexer::Worker',
	reporter_class        => 'MyCPAN::Indexer::Reporter::AsYAML',
	parallel_jobs         => 1,
	);

sub default { $Defaults{$_[1]} }

sub config_class { 'ConfigReader::Simple' }

sub get_config
	{
	my( $self, $file ) = @_;

	eval "require " . $self->config_class . "; 1";

	my $Config = $self->config_class->new( defined $file ? $file : () );

	foreach my $key ( keys %Defaults )
		{
		next if $Config->exists( $key );
		$Config->set( $key, $self->default( $key ) );
		}

	$Config;
	}
}

sub adjust_config
	{
	my( $self, $Config, @argv ) = @_;
	
	# set the directories to index
	unless( $Config->exists( 'backpan_dir') )
		{
		$Config->set( 'backpan_dir', [ @argv ? @argv : cwd() ] );
		}
	
	unless( ref $Config->get( 'backpan_dir' ) eq ref [] )
		{
		$Config->set( 'backpan_dir', [ $Config->get( 'backpan_dir' ) ] );
		}
		
	if( $Config->exists( 'report_dir' ) )
		{
		foreach my $subdir ( qw(success error) )
			{
			$Config->set(
				"${subdir}_report_subdir",
				catfile( $Config->get( 'report_dir' ), $subdir ),
				);
			}
		}		
			
	}
	
sub run
	{
	my( $self, @argv ) = @_;
	use vars qw( %Options );

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Process the options
	{
	my $run_dir = dirname( $0 );
	( my $script  = basename( $0 ) ) =~ s/\.\w+$//;

	local @ARGV = @argv;
	getopts( 'cl:f:', \%Options );
	@argv = @ARGV; # XXX: yuck

	$Options{f} ||= catfile( $run_dir, "$script.conf" );
	$Options{l} ||= catfile( $run_dir, "$script.log4perl" );
	}

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Minutely control the environment
	$self->setup_environment;
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Adjust config based on run parameters
	my $Config = $self->get_config( $Options{f} );

	$self->adjust_config( $Config, @argv );
	
	if( $Options{c} )
		{
		use Data::Dumper;
		print STDERR Dumper( $Config );
		exit;
		}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Load classes and check that they do the right thing
	my $Notes = {
		config     => $Config,
		UUID       => $self->get_uuid(),
		tempdirs   => [],
		log_file   => $Options{l},
		};

	$self->setup_logging( $Notes );

	$self->setup_dirs( $Notes );


	{
	my @components = $self->components;

	foreach my $tuple ( @components )
		{
		my( $directive, $default_class, $method ) = @$tuple;

		my $class = $Config->get( $directive ) || $default_class;

		eval "require $class" or die "$@\n";
		die "$directive [$class] does not implement $method()"
			unless $class->can( $method );

		$logger->debug( "Calling $class->$method()" );
		$class->$method( $Notes );
		}

	}
	
	$self->cleanup_and_exit( $Notes );
	}

sub setup_environment
	{
	my %pass_through = map { $_, 1 } qw( DISPLAY USER HOME PWD TERM );

	foreach my $key ( keys %ENV )
		{
		delete $ENV{$key} unless exists $pass_through{$key}
		}

	$ENV{AUTOMATED_TESTING}++;
	}
	
sub setup_logging
	{
	my( $self, $Notes ) = @_;
	
	if( -e $Notes->{log_file} )
		{
		Log::Log4perl->init_and_watch( 
			$Notes->{log_file}, 
			$Notes->{config}->get( 'log_file_watch_time' )
			);
		}
	else
		{
		Log::Log4perl->easy_init( $Log::Log4perl::ERROR );
		}
	}
	
sub components
	{
	(
	[ qw( queue_class      MyCPAN::Indexer::Queue             get_queue      ) ],
	[ qw( dispatcher_class MyCPAN::Indexer::Parallel          get_dispatcher ) ],
	[ qw( reporter_class   MyCPAN::Indexer::Reporter::AsYAML  get_reporter   ) ],
	[ qw( worker_class     MyCPAN::Indexer::Worker            get_task       ) ],
	[ qw( interface_class  MyCPAN::Indexer::Interface::Curses do_interface   ) ],
	[ qw( reporter_class   MyCPAN::Indexer::Interface::Curses final_words    ) ],
	)
	}

sub cleanup_and_exit
	{
	my( $self, $Notes ) = @_;
	
	require File::Path;
	
	my @dirs = @{ $Notes->{tempdirs} }, $Notes->{config}->get('temp_dir');
	$logger->debug( "Dirs to remove are @dirs" );
	
	eval {
		no warnings;
		File::Path::rmtree [@dirs];
		};
	
	print STDERR "$@\n" if $@;
	
	$logger->error( "Couldn't cleanup before exiting: $@" ) if $@;
	
	exit 0;
	}
	
sub setup_dirs # XXX big ugly mess to clean up
	{
	my( $self, $Notes ) = @_;

	my $Config = $Notes->{config};
	
# Okay, I've gone back and forth on this a couple of times. There is 
# no default for temp_dir. I create it here so it's only set when I
# need it. It either comes from the user or on-demand creation. I then
# set it's value in the configuration.

	my $temp_dir = $Config->temp_dir || tempdir( DIR => cwd(), CLEANUP => 0 );
	$logger->debug( "temp_dir is [$temp_dir] [" . $Config->temp_dir . "]" );
	$Config->set( 'temp_dir', $temp_dir );
	push @{ $Notes->{tempdirs} }, $temp_dir;

	mkpath( $temp_dir ) unless -d $temp_dir;
	$logger->logdie( "temp_dir [$temp_dir] does not exist!" ) unless -d $temp_dir;

	foreach my $key ( qw(report_dir success_report_subdir error_report_subdir) )
		{
		my $dir = $Config->get( $key );
		
		mkpath( $dir ) unless -d $dir;
		$logger->logdie( "$key [$dir] does not exist!" ) unless -d $dir;
		}

	if( $Config->retry_errors )
		{
		my $glob = catfile( $Config->get( 'error_report_subdir' ), "*.yml" );
		$glob =~ s/( +)/(\\$1)/g;

		unlink glob( $glob );
		}
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

1;
