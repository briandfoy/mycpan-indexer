#!/usr/bin/perl
use strict;
use warnings;
no warnings 'uninitialized';

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
Log::Log4perl->init_and_watch( 'backpan_indexer.log4perl', 30 );

my $Config = ConfigReader::Simple->new( 'backpan_indexer.config',
	[ qw(temp_dir backpan_dir report_dir alarm copy_bad_dists retry_errors) ]
	);
die "Could not read config!\n" unless ref $Config;

chdir $Config->temp_dir;

$ENV{AUTOMATED_TESTING}++;

my $yml_dir       = catfile( $Config->report_dir, "meta"        );
my $yml_error_dir = catfile( $Config->report_dir, "meta-errors" );

print "Value of rtry is ", $Config->retry_errors , "\n";
print "Value of copy_bad_dists is ", $Config->copy_bad_dists , "\n";

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
# Figure out what to index
my @dists = do {
	if( @ARGV ) 
		{
		DEBUG( "Taking dists from command line" );
		@ARGV 
		}
	else 
		{
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
	DEBUG( "[dist #$count] Parent [$$] processing $dist\n" );
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

	my $out_dir = $yml_error_dir;
	
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm( $Config->alarm || 15 );
	my $info = eval { MyCPAN::Indexer->run( $dist ) };

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
