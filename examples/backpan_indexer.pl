#!/usr/bin/perl
use strict;
use warnings;

use ConfigReader::Simple;
use Data::Dumper;
use File::Basename;
use File::Find;
use File::Find::Closures qw(find_by_regex);
use File::Spec::Functions qw(catfile);

use Log::Log4perl qw(:easy);
use YAML;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The Set up
Log::Log4perl->init( 'backpan_indexer.log4perl' );

my $Config = ConfigReader::Simple->new( 'backpan_indexer.config',
	[ qw(temp_dir backpan_dir report_dir) ]
	);
die "Could not read config!\n" unless ref $Config;

chdir $Config->temp_dir;

$ENV{AUTOMATED_TESTING}++;

my $yml_dir       = catfile( $Config->report_dir, "meta"        );
my $yml_error_dir = catfile( $Config->report_dir, "meta-errors" );

mkdir $yml_dir,       0755 unless -d $yml_dir;
mkdir $yml_error_dir, 0755 unless -d $yml_error_dir;

my $errors = 0;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Figure out what to index
my @dists = do {
	if( @ARGV ) { @ARGV }
	else {
		my( $wanted, $reporter ) = find_by_regex( qr/\.(t?gz|zip)$/ );
		
		find( $wanted, $Config->backpan_dir );
		$reporter->();
		}
	};
	
#DEBUG( "Dists to process are\n\t", join "\n\t", @dists, "\n" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# The meat of the issue
INFO( "Run started - " . @dists . " dists to process" );

my $count = 0;
foreach my $dist ( @dists )
	{
	#DEBUG( "Parent [$$] processing $dist\n" );
	chomp $dist;

	if( my $pid = fork ) { waitpid $pid, 0 }
	else                 { child_tasks( $dist ); exit }

	$count++;
	}
 
INFO( "Run ended - $count dists processed" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
sub child_tasks
	{
	my $dist = shift;
	
	my $basename = check_for_previous_result( $dist );
	return unless $basename;
	
	DEBUG( "Child [$$] processing $dist\n" );
		
	require MyCPAN::Indexer;
	
	unless( chdir $Config->temp_dir )
		{
		ERROR( "Could not change to " . $Config->temp_dir . " : $!\n" );
		exit 255;
		}

	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm 15;
	my $info = eval { MyCPAN::Indexer->run( $dist ) };
	print "$@" unless defined $info;
	alarm 0;
			
	ERROR( "$basename did not complete\n" ) 
		unless $info->run_info( 'completed' );
		
	my $dir = $info->run_info( 'completed' ) ? $yml_dir : $yml_error_dir;
	my $out_path = catfile( $dir, "$basename.yml" );
	
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
	
	if( -e $yml_path || -e $yml_error_path )
		{
		#INFO( "Found run output for $basename. Skipping...\n" );
		return;
		}
		
	return $basename;
	}
