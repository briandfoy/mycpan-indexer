#!/usr/bin/perl
use strict;
use warnings;

use Curses;
use List::Util qw(min);
use Term::ANSIColor;
use Parallel::ForkManager;


begin();

my @queue = map { int( rand( 10000 ) ) } (1) x int( rand( 100 ) );
my $queue = scalar @queue;

do_stuff();

END{ end(); }



my $header_row = 0;


refresh;

my $processed = 0;
my @errors    = ();
my @recent    = ();

sub do_stuff
	{
	refresh_total( $queue );
	
	my $forker = Parallel::ForkManager->new( 5 );
	
	$forker->run_on_finish( sub {
		my $pid = shift;
		@recent = grep $_->[0] != $pid, @recent;
		} );
	
	foreach my $item ( @queue )
		{
		if( $item % 9 == 0 ) {
			unshift @errors, $item;
			#addstr( $header_row + 1, 45, sprintf "% 9d", scalar @errors );
			refresh_errors();
			}
			
		addstr( 8, 12, 
			sprintf( "%3d", $item )
			);
		
		refresh_processed( $queue, ++$processed );
		refresh;

		my $pid;
		
		$pid = $forker->start and do { 
			unshift @recent, [ $pid, $item ]; refresh_recent(); next 
			};		
		
		
		sleep int rand 4;
		
		$forker->finish;
		}
	
	$forker->wait_all_children;
	
	}
	
sub begin
	{	
	initscr;
	start_color;
	draw_labels();
	}
	
sub draw_labels
	{	
	attron( A_REVERSE );
	
	addstr( 0, 0, "BackPAN Indexer 1.00" );
	
	{
	my $row = 2;
	foreach my $label ( qw(Total Done Left Errors) )
		{
		addstr( $row++, 0, sprintf "%6s", $label )
		}
	}
	
	{
	my $row = 2;
	foreach my $label ( qw(UUID Start Elapsed Rate) )
		{
		addstr( $row++, 22, sprintf "%7s", $label )
		}
	}

	my $proc_row = 7;
	
	addstr( $proc_row,  0, " #" );
	addstr( $proc_row,  5, "PID" );
	addstr( $proc_row, 12, "Processing" );

	foreach my $i ( 1 .. 5 )
		{
		addstr( $proc_row + $i, 0, sprintf "%2s", $i );
		}
		
	addstr( 15,  0, "Errors" );
	
	attroff( A_REVERSE );
	
	refresh;
	}
	
sub end
	{	
	addstr(24, 0, '' );
	endwin;
	print "\n";
	}

sub refresh_total
	{
	addstr( 2, 7, sprintf "%7s", '       ' );
	addstr( 2, 7, sprintf "%7s", $_[0] );
	refresh;
	}

sub refresh_processed
	{
	addstr( 3, 7, sprintf "%7s", '       ' );
	addstr( 3, 7, sprintf "%7s", $_[1] );

	addstr( 4, 7, sprintf "%7s", '       ' );
	addstr( 4, 7, sprintf "%7s", $_[0] - $_[1] );

	refresh;
	}
	
sub refresh_errors
	{
	addstr( 5, 7, sprintf "%7s", '       ' );
	addstr( 5, 7, sprintf "%7s", scalar @errors );

	my $rows = min( scalar @errors, 10 );
	foreach my $row ( 1 .. $rows )
		{
		addstr( $row + 15, 0, ' ' x 10 );
		addstr( $row + 15, 0, sprintf "%10s", $errors[$row - 1] );
		}
		
	refresh;
	}
	
sub refresh_recent
	{
	my $rows = min( scalar @recent, 10 );
	foreach my $row ( 1 .. $rows )
		{
		addstr( $row + 6, 20, ' ' x 10 );
		addstr( $row + 6, 20, sprintf "%10s", $recent[$row - 1][0] );
		refresh;
		}
	}