#!/usr/bin/perl
use strict;

use Data::Dumper;
use File::Basename;
use File::Find;
use File::Find::Closures qw(find_by_regex);

use Log::Log4perl qw(:easy);
use YAML;

Log::Log4perl->easy_init($DEBUG);


chdir "/Users/brian/Desktop/temp";

my( $wanted, $reporter ) = find_by_regex( qr/\.(t?gz|zip)$/ );

find( $wanted, '/Users/brian/Desktop/BackPAN Indexer/dual-life' );

my $count = 0;

$ENV{AUTOMATED_TESTING}++;

my $path = "/Users/brian/Desktop/BackPAN\\ Indexer/dual-life/T/*/*/*";
my $yml_dir = "/Users/brian/Desktop/BackPAN\ Indexer/meta";
my $yml_error_dir = "/Users/brian/Desktop/BackPAN\ Indexer/meta-errors";
mkdir $yml_dir, 0755 unless -d $yml_dir;
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
		
	my $yml_path = File::Spec->catfile( $yml_dir, "$basename.yml" );
	my $yml_error_path = File::Spec->catfile( $yml_error_dir, "$basename.yml" );
	
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
			
		require "/Users/brian/Desktop/BackPAN\ Indexer/indexer.pl";
		chdir "/Users/brian/Desktop/BackPAN\ Indexer/temp";

		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm 15;
		my $info = eval { MyCPAN::Indexer->run( $dist ) };
		alarm 0;
		
		
		my $completed = $info->{run_info}{completed};
		
		ERROR( "!!! $basename did not complete\n" ) unless $completed;
			
		my $dir = $completed ? $yml_dir : $yml_error_dir;
		my $out_path = File::Spec->catfile( $dir, "$basename.yml" );
		
		open my($fh), ">", $out_path or die "Could not open $yml_path: $!\n";
		print $fh Dump( $info );
		
		exit;
		}

	#last #if $count++ > 100;
	}
	