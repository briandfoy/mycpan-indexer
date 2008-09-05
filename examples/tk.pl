use strict;
use warnings;

use Tk;
use Parallel::ForkManager;


    
my $Vars = { 
	Total    => 100,
	Started  => scalar localtime,
	_started => time,
	UUID     => 'asdfasfgadsfgadfgdfsg',
	recent   => [ qw() ],
	PID      => [ qw() ],
	errors   => [ qw() ],
	};

my $forker = Parallel::ForkManager->new( 5 );

my $mw = do_tk_stuff( $Vars );
$mw->repeat( 500, \ &the_steak );

MainLoop;


sub the_steak
	{
	sleep int( rand );
	
	$Vars->{_elapsed} = time - $Vars->{_started};
	$Vars->{Elapsed} = elapsed( $Vars->{_elapsed} );
	unshift @{ $Vars->{PID} }, int rand 7000;
	unshift @{ $Vars->{recent} }, int rand 65535;

	$Vars->{Done}++;
	$Vars->{Left} = $Vars->{Total} - $Vars->{Done};
	
	$Vars->{Rate} = sprintf "%.2f / sec ", 
		eval { $Vars->{Done} / $Vars->{_elapsed} };
	
	if( int(rand(100)) % 20 == 0 )
		{
		unshift @{ $Vars->{errors} }, $Vars->{recent}[0];
		}
	}

BEGIN {
my %hash = ( days => 864000, hours => 3600, minutes => 60 );

sub elapsed
	{
	my $seconds = shift;
	
	my @v;
	foreach my $key ( qw(days hours minutes) )
		{
		push @v, int( $seconds / $hash{$key} );
		$seconds -= $v[-1] * $hash{$key}
		}
		
	push @v, $seconds;
	
	sprintf "%dd %02dh %02dm %02ds", @v;
	}
}

sub do_tk_stuff 
	{
	my $mw = MainWindow->new;
	
	$mw->resizable( 0, 0 );
	$mw->title( 'BackPAN Indexer 1.00' );
	my $menubar = _menubar( $mw );
	
	my( $progress, $top, $middle, $bottom ) = map {
		$mw->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
		} 1 .. 4;
	
	
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	my $tracker = _make_frame( $top, 'left' );
	
	my $tracker_left        = $tracker->Frame->pack( -anchor => 'w', -side => 'left' );
	foreach my $label ( qw(Total Done Left Errors ) )
		{
		my $frame = $tracker_left->Frame->pack( -side => 'top' );
		$frame->Label( -text => $label, -width => 6 )->pack( -side => 'left' );
		$frame->Entry( -width => 6, -textvariable => \ $Vars->{$label}, -relief => 'flat' )->pack( -side => 'right' );
		}
	
	my $tracker_right        = $tracker->Frame->pack( -anchor => 'w', -side => 'left'  );
	foreach my $label ( qw( UUID Started Elapsed Rate ) )
		{
		my $frame = $tracker_right->Frame->pack( -side => 'top' );
		$frame->Label( -text => $label, -width => 6 )->pack( -side => 'left' );
		$frame->Entry( -textvariable => \ $Vars->{$label}, -relief => 'flat' )->pack( -side => 'right' );
		}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	require Tk::ProgressBar;
	
	my $bar = $progress->Frame->pack( -anchor => 'w', -side => 'left', -expand => 1, -fill => 'x' );		
	$bar->ProgressBar(
		-from     => 0,
		-to       => $Vars->{Total},
		-variable => \ $Vars->{Done},
		-colors   => [ 0, 'green',],
		-gap      => 0,
		)->pack( -side => 'top', -fill => 'x',  );

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	my @recent = qw( a b c d e );
	my $jobs    = $middle->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );;
	
	my $count_frame = _make_frame( $jobs, 'left' );
	$count_frame->Label( -text => '#',          -width =>  3 )->pack( -side => 'top' );
	$count_frame->Listbox(
		-height => 5,
		-width  => 3,
		-listvariable  => [ 1 .. 5 ],
		)->pack( -side => 'bottom');
		
	my $pid_frame  = _make_frame( $jobs, 'left' );
	$pid_frame->Label( -text => 'PID',        -width =>  6 )->pack( -side => 'top' );
	$pid_frame->Listbox(
		-height => 5,
		-width  => 6,
		-listvariable  => $Vars->{PID},
		)->pack( -side => 'bottom');
	
	my $proc_frame = $jobs->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
	$proc_frame->Label( -text => 'Processing', -width => 35 )->pack( -side => 'top' );
	$proc_frame->Listbox(
		-height => 5,
		-listvariable  => $Vars->{recent},
		)->pack( -side => 'bottom', -expand => 1, -fill => 'x');
	
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	my @errors = qw( dog bird cat );
	my $errors  = $bottom->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
	$errors->Label( -text => 'Errors', )->pack( -side => 'top', -anchor => 'w');
	$errors->Listbox(
		-height => 10,
		-listvariable => $Vars->{errors},
		)->pack(
			-expand => 1,
			-fill => 'x',
			-side => 'left',
			-anchor => 'w',
				);
				
				
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	return $mw;
	}
	

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