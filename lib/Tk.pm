package MyCPAN::Indexer::Interface::Tk;

use Log::Log4perl qw(:easy);
use Tk;

=head1 NAME

MyCPAN::Indexer::Interface::Tk - Index a Perl distribution

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Tk

=head1 DESCRIPTION

This class presents the information as the indexer runs, using Tk.

=head2 Methods

=over 4

=item do_interface( $Vars )


=cut

sub do_interface 
	{
	my( $Vars ) = @_;
	
	use Tk;

	my $mw = MainWindow->new;
	$mw->geometry('400x300');	

	$mw->resizable( 0, 0 );
	$mw->title( 'BackPAN Indexer 1.00' );
	my $menubar = _menubar( $mw );
	
	my( $progress, $top, $middle, $bottom ) = map {
		$mw->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
		} 1 .. 4;
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	my $tracker = _make_frame( $top, 'left' );
	
	my $tracker_left = $tracker->Frame->pack( 
		-anchor => 'w', 
		-side   => 'left' 
		);
	foreach my $label ( qw(Total Done Left Errors ) )
		{
		my $frame = $tracker_left->Frame->pack( -side => 'top' );
		$frame->Label( -text => $label, -width => 6 )->pack( -side => 'left' );
		$frame->Entry( 
			-width => 6, 
			-textvariable => \ $Vars->{$label}, 
			-relief => 'flat' 
			)->pack( -side => 'right' );
		}
	
	my $tracker_right = $tracker->Frame->pack( 
		-anchor => 'w', 
		-side   => 'left'  
		);
	foreach my $label ( qw( UUID Started Elapsed Rate ) )
		{
		my $frame = $tracker_right->Frame->pack( -side => 'top' );
		$frame->Label( -text => $label, -width => 6 )->pack( -side => 'left' );
		$frame->Entry( 
			-textvariable => \ $Vars->{$label}, 
			-relief => 'flat' 
			)->pack( -side => 'right' );
		}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	require Tk::ProgressBar;
	
	my $bar = $progress->Frame->pack( 
		-anchor => 'w', 
		-side   => 'left', 
		-expand => 1, 
		-fill   => 'x' 
		);		
	$bar->ProgressBar(
		-from     => 0,
		-to       => $Vars->{Total},
		-variable => \ $Vars->{Done},
		-colors   => [ 0, 'green',],
		-gap      => 0,
		)->pack( -side => 'top', -fill => 'x',  );

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	my @recent = qw( a b c d e );
	my $jobs    = $middle->Frame->pack( -anchor => 'w', -expand => 1, -fill => 'x' );
	
	my $count_frame = _make_frame( $jobs, 'left' );
	$count_frame->Label( -text => '#',          -width =>  3 )->pack( -side => 'top' );
	$count_frame->Listbox(
		-height => 5,
		-width  => 3,
		-listvariable  => [ 1 .. $Vars->{Threads} ],
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
			-fill   => 'x',
			-side   => 'left',
			-anchor => 'w',
			);
				
				
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	_make_interface_callback( $Vars );
	$mw->repeat( 1_000, $Vars->{interface_callback} );

	MainLoop;
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
	}

sub _make_interface_callback
	{
	my( $Vars ) = @_;
	
	$Vars->{interface_callback} = sub {
		return unless $Vars->{Left};
		
		$Vars->{_elapsed} = time - $Vars->{_started};
		$Vars->{Elapsed} = elapsed( $Vars->{_elapsed} );
	
		my $item = ${ $Vars->{queue} }[ $Vars->{queue_cursor}++ ];
				
		if( my $pid = $Vars->{dispatcher}->start )
			{ #parent
			
			unshift @{ $Vars->{PID} }, $pid;
			unshift @{ $Vars->{recent} }, $item;
			
			$Vars->{Done}++;
			$Vars->{Left} = $Vars->{Total} - $Vars->{Done};
			
			$Vars->{Rate} = sprintf "%.2f / sec ", 
				eval { $Vars->{Done} / $Vars->{_elapsed} };
			
			}
		else
			{ # child
			$Vars->{child_task}( $item );
			$Vars->{dispatcher}->finish;
			}
	
		1;
		};
	}	

1;

=back


=head1 SEE ALSO

MyCPAN::Indexer

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut