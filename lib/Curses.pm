package MyCPAN::Indexer::Interface::Curses;
use strict;
use warnings;

use Log::Log4perl qw(:easy);
use Curses;

=head1 NAME

MyCPAN::Indexer::Interface::Curses - Present the run info in a terminal

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Curses

=head1 DESCRIPTION

This class presents the information as the indexer runs, using Curses.

=head2 Methods

=over 4

=item do_interface( $Notes )


=cut

sub do_interface 
	{
	my( $class, $Notes ) = @_;
	print "Calling do_interface\n";
	
	initscr();
	noecho();
	raw();
	
	$Notes->{curses}{rows} = LINES();
	$Notes->{curses}{cols} = COLS();
	
	addstr( 0, 0, 'BackPAN Indexer 1.00' );	
	refresh();
	
	my $count = 0;
	while( 1 )
		{
		$Notes->{interface_callback}->();

		_update_screen( $Notes );
		
		sleep 1;
		
		}

	}

{
my $labels = {
	# Label, row, column, key, key length, value length
	Total      => [ qw(3  0 Total         6   6) ],
	Done       => [ qw(4  0 Done          6   6) ],
	Left       => [ qw(5  0 Left          6   6) ],
	Errors     => [ qw(6  0 Errors        6   6) ],
	
	UUID       => [ qw(3 20 UUID          7  30) ],
	Started    => [ qw(4 20 Started       7 -30) ],
	Elapsed    => [ qw(5 20 Elapsed       7 -30) ],
	Rate       => [ qw(6 20 Rate          7 -30) ],

	'##'       => [ qw(8  0 ##            2   0) ],
	PID        => [ qw(8  4 PID           6   0) ],
	Processing => [ qw(8 12 Processing   40   0) ],

	ErrorList  => [ qw(15 0 Errors        7   0) ],
	
	};

my $values = {};

sub _update_screen
	{
	&_update_labels;
	&_update_progress;
	&_update_values;
	}
	
sub _update_labels
	{
	my( $Notes ) = @_;
	
	#print "Calling _update_screen\n";
	
	foreach my $key ( keys %$labels )
		{
		my $tuple = $labels->{$key};
		move( @$tuple[0,1]  );
		refresh();
		addstr( @$tuple[0,1,2] );
		refresh;
		}

	my $row = $labels->{'##'}[0];
	foreach my $i ( 1 .. $Notes->{Threads} )
		{
		my $width = $labels->{'##'}[3];
		move( $row + $i, $labels->{'##'}[1] );
		refresh();
		addstr( $row + $i, $labels->{'##'}[1], 
			sprintf "%${width}s", $i );
		refresh;
		}

	refresh();
	}

sub _update_progress
	{
	my( $Notes ) = @_;

	my $progress = COLS() / $Notes->{Total} * $Notes->{Done};
	
	move( 2, 0 );
	refresh;
	addstr( 2, 0, '*' x $progress );
	refresh;	
	}
	
sub _update_values
	{
	my( $Notes ) = @_;
		
	no warnings;
	foreach my $key ( qw() )
		{
		my $tuple = $labels->{$key};

		next unless $tuple->[4];

		move( 
			$tuple->[0],
			$tuple->[1] + $tuple->[3] + 2
			);
		refresh;
		addstr( 
			$tuple->[0], 
			$tuple->[1] + $tuple->[3] + 2, 
			sprintf "%" . $tuple->[4] . "s", $Notes->{$tuple->[2]} 
			);
		refresh;
		}

=pod

	my $row = $labels->{PID}[0];
	foreach my $i ( 1 .. $Notes->{Threads} )
		{
		my $width = $labels->{'##'}[3];
		addstr( $row + $i, $labels->{'##'}[1], 
			sprintf "%${width}s", $i );

		$width = $labels->{PID}[3];
		addstr( $row + $i, $labels->{PID}[1], 
			sprintf "%${width}s", $Notes->{PID}[$i-1] );

		$width = $labels->{Processing}[3];
		addstr( $row + $i, $labels->{Processing}[1], ' ' x 70 );
		addstr( $row + $i, $labels->{Processing}[1], 
			sprintf "%${width}s", $Notes->{recent}[$i-1] );
		
		}

=cut

	}
}

END { endwin() }

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

1;