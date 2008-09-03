#!/usr/bin/perl
use strict;
use warnings;

use Curses;
use List::Util qw(min);


my $win = begin();

	my @queue = map { int( rand( 10000 ) ) } (1) x int( rand( 100 ) );
	my $queue = scalar @queue;

do_stuff( $win );

end( $win );



my $header_row = 0;


$win->refresh;

my $processed = 0;
my @errors    = ();
my @recent    = ();

sub do_stuff
	{
	refresh_total( $queue );
	
	foreach my $item ( @queue )
		{
		unshift @recent, $item;
		
		
		if( $item % 9 == 0 ) {
			unshift @errors, $item;
			#$win->addstr( $header_row + 1, 45, sprintf "% 9d", scalar @errors );
			refresh_errors();
			}
			
		$win->addstr( 8, 12, 
			sprintf( "%3d", $item )
			);
		
		refresh_recent();
		refresh_processed( $queue, ++$processed );
		$win->refresh;
		
		sleep 1;
		}
	
	}
	
sub begin
	{	
	my $win = Curses->new;
	
	draw_labels( $win );
	
	$win;
	}
	
sub draw_labels
	{
	my $win = shift;
	
	$win->addstr( 0, 0, "BackPAN Indexer 1.00" );
	
	{
	my $row = 2;
	foreach my $label ( qw(Total Done Left Errors) )
		{
		$win->addstr( $row++, 0, sprintf "%6s", $label )
		}
	}
	
	{
	my $row = 2;
	foreach my $label ( qw(UUID Start Elapsed Rate) )
		{
		$win->addstr( $row++, 22, sprintf "%7s", $label )
		}
	}

	my $proc_row = 7;
	
	$win->addstr( $proc_row,  0, " #" );
	$win->addstr( $proc_row,  5, "PID" );
	$win->addstr( $proc_row, 12, "Processing" );

	foreach my $i ( 1 .. 5 )
		{
		$win->addstr( $proc_row + $i, 0, sprintf "%2s", $i );
		}
		
	$win->addstr( 15,  0, "Errors" );
	
	$win->refresh;
	}
	
sub end
	{
	my $win = shift;
	
	$win->addstr(24, 0, '' );
	endwin;
	print "\n";
	}

sub refresh_total
	{
	$win->addstr( 2, 7, sprintf "%7s", '       ' );
	$win->addstr( 2, 7, sprintf "%7s", $_[0] );
	$win->refresh;
	}

sub refresh_processed
	{
	$win->addstr( 3, 7, sprintf "%7s", '       ' );
	$win->addstr( 3, 7, sprintf "%7s", $_[1] );

	$win->addstr( 4, 7, sprintf "%7s", '       ' );
	$win->addstr( 4, 7, sprintf "%7s", $_[0] - $_[1] );

	$win->refresh;
	}
	
sub refresh_errors
	{
	$win->addstr( 5, 7, sprintf "%7s", '       ' );
	$win->addstr( 5, 7, sprintf "%7s", scalar @errors );

	my $rows = min( scalar @errors, 10 );
	foreach my $row ( 1 .. $rows )
		{
		$win->addstr( $row + 15, 0, ' ' x 10 );
		$win->addstr( $row + 15, 0, sprintf "%10s", $errors[$row - 1] );
		}
		
	$win->refresh;
	}
	
sub refresh_recent
	{
	return 1;
	my $rows = min( scalar @recent, 10 );
	foreach my $row ( 1 .. $rows )
		{
		$win->addstr( $row + 6, 20, ' ' x 10 );
		$win->addstr( $row + 6, 20, sprintf "%10s", $recent[$row - 1] );
		$win->refresh;
		}
	}