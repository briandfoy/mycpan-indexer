#!/usr/bin/perl

use File::Basename;
use Parallel::ForkManager;

my $basename = basename( $0 );
my $db_file = "$basename";
unlink "$db_file.db";

print "$^X $]\n";
print "Parallel::ForkManager: ", Parallel::ForkManager->VERSION, "\n";

$pm = Parallel::ForkManager->new(15);

foreach $data ( 0 .. 1000 ) 
	{
	my $pid = $pm->start and next;
	
	my $key = ( 'a' .. 'z' )[ rand 26 ];
	
	dbmopen my %HASH, $db_file, 0755;

	$HASH{$key}++;
	
	dbmclose %HASH;
	
	$pm->finish; # Terminates the child process
	}
	
$pm->wait_all_children;

dbmopen my %HASH, $db_file, 0755;

foreach my $key ( sort keys %HASH )
	{
	print "$key: $HASH{$key}\n";
	}