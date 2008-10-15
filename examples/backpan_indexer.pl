#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';
use vars qw( %Options );

use blib;
use Cwd qw(cwd);
use Data::Dumper;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Getopt::Std;
use Log::Log4perl;

$|++;

my $logger = Log::Log4perl->get_logger( 'backpan_indexer' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Process the options
{
my $run_dir = dirname( $0 );
( my $script  = basename( $0 ) ) =~ s/\.\w+$//;

getopts('i:f:', \%Options); 

$Options{f} ||= catfile( $run_dir, "$script.conf" );
$Options{i} ||= catfile( $run_dir, "$script.log4perl" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Minutely control the environment
{
my %pass_through = map { $_, 1 } qw( DISPLAY USER HOME PWD TERM );

foreach my $key ( keys %ENV ) 
	{ 
	delete $ENV{$key} unless exists $pass_through{$key} 
	}

$ENV{AUTOMATED_TESTING}++;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The set up
Log::Log4perl->init_and_watch( $Options{i}, 30 );

my $Config = get_config( $Options{f} );

setup_dirs( $Config );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Load classes and check that they do the right thing
my $Notes = { 
	config     => $Config,
	UUID       => get_uuid(),
	};

{
my @components = (
	[ qw( queue_class      MyCPAN::Indexer::Queue             get_queue      ) ],
	[ qw( dispatcher_class MyCPAN::Indexer::Parallel          get_dispatcher ) ],
	[ qw( reporter_class   MyCPAN::Indexer::Reporter::AsYAML  get_reporter   ) ],
	[ qw( worker_class     MyCPAN::Indexer::Worker            get_task       ) ],
	[ qw( interface_class  MyCPAN::Indexer::Interface::Curses do_interface   ) ],
	[ qw( reporter_class   MyCPAN::Indexer::Interface::Curses final_words    ) ],
	);

foreach my $tuple ( @components )
	{
	my( $directive, $default_class, $method ) = @$tuple;
	
	my $class = $Config->get( $directive) || $default_class;
	
	eval "require $class" or die "$@\n";
	die "$directive [$class] does not implement $method()" 
		unless $class->can( $method );
		
	$logger->debug( "Calling $class->$method()" );
	$class->$method( $Notes );
	}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
sub get_config
	{
	require ConfigReader::Simple;

	my $file = shift;
	
	$logger->debug( "Conf file is $file" );
	
	my $Config = ConfigReader::Simple->new( $file,
		[ qw(temp_dir backpan_dir report_dir alarm 
			copy_bad_dists retry_errors indexer_class) ]
		);
		
	$logger->fatal( "Could not read config!" ) unless ref $Config;
	
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
	
	$logger->debug( "Value of retry is " . $Config->retry_errors );
	$logger->debug( "Value of copy_bad_dists is " . $Config->copy_bad_dists );
	
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
