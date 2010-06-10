#!perl
use strict;
use warnings;

use DBM::Deep;
use POSIX qw(strftime);

# Games-LogicPuzzle-0.10.tar.gz	Games-LogicPuzzle	1048217971	20030321	2003Q1	4778	AADLER	released	0.10

my $file = 'backpan_stats.db';
unlink $file;
my $db = DBM::Deep->new( $file );

my $author   = $db->{author};
my $releases = $db->{releases};
#my $size     = $db->{bytes};
my $earliest = $db->{earliest};

$|++;
my $count = 0;
while( <> )
	{
	chomp;
	print "." unless $count++ % 10;
	print "\n[$count]" unless $count % 1000;
	
	my( $file, $dist, $epoch, $ymd, $q, $bytes, $pauseid, $maturity, $version ) 
		= split /\t/;
		
	my( $year ) = substr( $ymd, 0, 4 );
	my $week_number = strftime(  "%W", localtime( $epoch ) );
	my $day_of_week = ( localtime( $epoch ) )[6];
	
	$db->{author}{$year}{$pauseid}{$maturity}++;
	$db->{author}{$q}{$pauseid}{$maturity}++;
	$db->{author}{week}{$year}{$week_number}{$pauseid}{$maturity}++;
	$db->{author}{weekday}{$day_of_week}{$maturity}++;

	push @{$db->{activity}{$pauseid}{activity}}, $epoch;
	
	$db->{releases}{$maturity}{$year}{$dist}++;
	$db->{releases}{$maturity}{$q}{$dist}++;
	$db->{releases}{$maturity}{week}{$year}{$week_number}{$dist}++;
	$db->{releases}{$maturity}{$day_of_week}++;

	{
	no warnings 'uninitialized';
	$db->{size}{$year}{$maturity} += $bytes;
	$db->{size}{$q}{$maturity} += $bytes;
	$db->{size}{week}{$year}{$week_number}{$maturity}++;
	$db->{size}{author}{$pauseid} += $bytes;
	$db->{size}{weekday}{$day_of_week} += $bytes;
	}
	
	$db->{earliest}{$dist} = $epoch 
		if( (! defined $db->{earliest}{$dist}) || $epoch < $db->{earliest}{$dist} );
	
	print "Earliest [$dist] is [$db->{earliest}{$dist}]\n";
	}

foreach my $year ( grep { /^\d\d\d\d$/ } keys %{ $db->{bytes} } )
	{
	printf "%d bytes for %d\n", $db->{bytes}{$year}, $year;
	}

=pod

     %V    is replaced by the week number of the year (Monday as the first day of the week) as a decimal number (01-53).  If
           the week containing January 1 has four or more days in the new year, then it is week 1; otherwise it is the last
           week of the previous year, and the next week is week 1.

     %v    is equivalent to ``%e-%b-%Y''.

     %W    is replaced by the week number of the year (Monday as the first day of the week) as a decimal number (00-53).

     %w    is replaced by the weekday (Sunday as the first day of the week) as a decimal number (0-6).
     
=cut
