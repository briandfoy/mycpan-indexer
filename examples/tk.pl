use strict;
use warnings;

use Tk;


my $mw = MainWindow->new( );
$mw->resizable( 0, 0 );
$mw->title( 'BackPAN Indexer 1.00' );
my $menubar = _menubar( $mw );

my( $top, $middle, $bottom ) = map {
	_make_frame( $mw, 'top' );
	} 1 .. 3;



my $tracker = _make_frame( $top, 'left' );

my $tracker_left  = _make_frame( $tracker, 'left' );
my $tracker_left_labels => _make_frame( $tracker_left, 'left' );
my $tracker_left_values => _make_frame( $tracker_left, 'right' );


foreach my $label ( qw(Total Done Left Errors ) )
	{
	$tracker_left_labels->Label( -text => $label )->pack( -side => 'left' );
	}

my $tracker_right = _make_frame( $tracker, 'right' );
my $tracker_right_labels => _make_frame( $tracker_right, 'right' );
my $tracker_right_values => _make_frame( $tracker_right, 'right' );
foreach my $label ( qw(UUID Start Elapsed Rate ) )
	{
	$tracker_right_labels->Label( -text => $label )->pack( -side => 'right' );
	}


my @recent = qw( a b c d e );
my $jobs    = _make_frame( $middle, 'left' );

my $count_frame = _make_frame( $jobs, 'left' );
$count_frame->Label( -text => '#',          -width =>  3 )->pack( -side => 'top' );
$count_frame->Listbox(
	-height => 5,
	-width  => 3,
	-listvariable => [ 1 .. 5 ],
	)->pack( -side => 'bottom');
	
my $pid_frame  = _make_frame( $jobs, 'left' );
$pid_frame->Label( -text => 'PID',        -width =>  6 )->pack( -side => 'top' );
$pid_frame->Listbox(
	-height => 5,
	-width  => 6,
	-listvariable => [ map { int rand 65535 } 1 .. 5 ],
	)->pack( -side => 'bottom');

my $proc_frame = _make_frame( $jobs, 'left' );
$proc_frame->Label( -text => 'Processing', -width => 35 )->pack( -side => 'top' );
$proc_frame->Listbox(
	-height => 5,
	-width  => 45,
	-listvariable => \ @recent,
	)->pack( -side => 'bottom');

my @errors = qw( dog bird cat );
my $errors  = _make_frame( $bottom, 'bottom' );
$errors->Label( -text => 'Errors', )->pack( -side => 'top' );
$errors->Listbox(
	-height => 10,
	-listvariable => \ @recent,
	)->pack( -side => 'bottom',
			-anchor => 'e',
			-expand => 1,
			);

MainLoop;

sub _make_frame
	{
	my $mw   = shift;
	my $side = shift;
	
	my $frame = $mw->Frame->pack(
		-anchor => 'n',
		-side   => $side,
		);

	return $frame;
	}
	
sub _menubar
	{
	my $mw      = shift;

	$mw->configure( -menu => my $menubar = $mw->Menu );
	my $file_items = [
		[qw( command ~Quit -accelerator Ctrl-q -command ) => sub { exit } ]
		];

	my( $edit_items, $help_items, $play_items, $refresh_items ) = ( [], [], [] );

		
	my $file = _menu( $menubar, "~File",     $file_items );
	my $edit = _menu( $menubar, "~Edit",     $edit_items );
	
	return $menubar;
	}
	
sub _menu
	{
	my $menubar = shift;
	my $title   = shift;
	my $items   = shift;
	
	my $menu = $menubar->cascade( 
		-label     => $title, 
		-menuitems => $items,
		-tearoff   => 0,
		 );
		 
	return $menu;
	};