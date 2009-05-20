package MyCPAN::Indexer::Dispatch::Serial;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.21';

use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Dispatcher' );
	}

=head1 NAME

MyCPAN::Indexer::Dispatch::Serial - Pass out work in the same process

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	dispatch_class  MyCPAN::Indexer::Dispatch::Serial

=head1 DESCRIPTION

This class takes the list of distributions to process and passes them
out to the code that will do the work.

=head2 Methods

=over 4

=item get_dispatcher( $Notes )

Takes the $Notes hash and adds the C<dispatcher> key with a code
reference.

It adds to $Notes:

	dispatcher => sub { ... },

=cut

sub get_dispatcher
	{
	my( $class, $Notes ) = @_;

	$Notes->{interface_callback} = $class->_make_interface_callback( $Notes );
	}

sub _make_interface_callback
	{
	my( $class, $Notes ) = @_;

	foreach my $key ( qw(PID recent errors ) )
		{
		$Notes->{$key} = [ qw() ];
		}

	$Notes->{Total}        = scalar @{ $Notes->{queue} };
	$Notes->{Left}         = $Notes->{Total};
	$Notes->{Errors}       = 0;
	$Notes->{Done}         = 0;
	$Notes->{Started}      = scalar localtime;
	$Notes->{Finished}     = 0;

	$Notes->{queue_cursor} = 0;

	$Notes->{interface_callback} = sub {

		$logger->debug( "Start: Finished: $Notes->{Finished} Left: $Notes->{Left}" );

		unless( $Notes->{Left} )
			{
			$Notes->{Finished} = 1;
			return;
			};

		$Notes->{_started} ||= time;

		$Notes->{_elapsed} = time - $Notes->{_started};
		$Notes->{Elapsed}  = _elapsed( $Notes->{_elapsed} );

		my $item = ${ $Notes->{queue} }[ $Notes->{queue_cursor}++ ];

		$Notes->{Done}++;
		$Notes->{Left} = $Notes->{Total} - $Notes->{Done};
		$logger->debug( "Total: $Notes->{Total} Done: $Notes->{Done} Left: $Notes->{Left} Finished: $Notes->{Finished}" );

		no warnings;
		$Notes->{Rate} = sprintf "%.2f / sec ",
			eval { $Notes->{Done} / $Notes->{_elapsed} };

		$Notes->{child_task}( $item );

		1;
		};
	}

BEGIN {
my %hash = ( days => 864000, hours => 3600, minutes => 60 );

sub _elapsed
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

1;

=back


=head1 SEE ALSO

MyCPAN::Indexer, MyCPAN::Indexer::Tutorial

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

