#!/usr/bin/perl

use DBM::Deep;
use File::Basename;
use Parallel::ForkManager;

my $basename = basename( $0 );
my $db_file = "$basename.db";
unlink $db_file;

print "$^X $]\n";
print "Deep::DBM: ", DBM::Deep->VERSION, "\n";
print "Parallel::ForkManager: ", Parallel::ForkManager->VERSION, "\n";

$pm = Parallel::ForkManager->new(10);

foreach $data ( 0 .. 100 ) 
	{
	my $pid = $pm->start and next;

	sleep rand 3;
	
	my $key = ( 'a' .. 'z' )[ rand 26 ];
	
	my $db = DBM::Deep->new( 
		file    => $db_file,
		locking => 1,
		);

	$db->{$key}++;
	
	$pm->finish; # Terminates the child process
	}
	
$pm->wait_all_children;

my $db = DBM::Deep->new( $db_file );

foreach my $key ( keys %$db )
	{
	print "$key: $db->{$key}\n";
	}