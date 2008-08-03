#!/usr/bin/perl
use strict;

use ConfigReader::Simple;
use Data::Dumper;
use File::Basename;
use File::Find;
use File::Find::Closures qw(find_by_regex);
use File::Spec::Functions qw(catfile);

use Log::Log4perl qw(:easy);
use YAML;

Log::Log4perl->easy_init($DEBUG);

my $config = ConfigReader::Simple->new( 'backpan_indexer.config',
	[ qw(temp_dir backpan_dir report_dir) ]
	);
die "Could not read config!\n" unless ref $config;

chdir $config->temp_dir;

my( $wanted, $reporter ) = find_by_regex( qr/\.(t?gz|zip)$/ );

find( $wanted, $config->backpan_dir );

my $count = 0;

$ENV{AUTOMATED_TESTING}++;

my $yml_dir       = catfile( $config->report_dir, "meta"        );
my $yml_error_dir = catfile( $config->report_dir, "meta-errors" );

mkdir $yml_dir,       0755 unless -d $yml_dir;
mkdir $yml_error_dir, 0755 unless -d $yml_error_dir;

my $errors = 0;

my @dists = $reporter->();

DEBUG( "Dists to process are\n\t", join "\n\t", @dists, "\n" );

foreach my $dist ( @dists )
	{
	DEBUG( "Parent [$$] processing $dist\n" );
	chomp $dist;

	my $basename = basename( $dist );
	$basename =~ s/\.(tgz|tar\.gz|zip)$//;
		
	my $yml_path       = catfile( $yml_dir,       "$basename.yml" );
	my $yml_error_path = catfile( $yml_error_dir, "$basename.yml" );
	
	if( -e $yml_path || -e $yml_error_path )
		{
		INFO( "Found run output for $basename. Skipping...\n" );
		next;
		}

	my $pid = fork();
	
	if( $pid )
		{
		waitpid $pid, 0;
		}
	else
		{
		INFO( "Child [$$] processing $dist\n" );
			
		require MyCPAN::Indexer;
		
		unless( chdir $config->temp_dir )
			{
			ERROR( "Could not change to " . $config->temp_dir . " : $!\n" );
			exit 255;
			}

		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm 15;
		my $info = eval { MyCPAN::Indexer->run( $dist ) };
		alarm 0;
		
		
		my $completed = $info->{run_info}{completed};
		
		ERROR( "$basename did not complete\n" ) unless $completed;
			
		my $dir = $completed ? $yml_dir : $yml_error_dir;
		my $out_path = catfile( $dir, "$basename.yml" );
		
		open my($fh), ">", $out_path or die "Could not open $yml_path: $!\n";
		print $fh Dump( $info );
		
		exit;
		}

	#last #if $count++ > 100;
	}
	