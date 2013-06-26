package MyCPAN::Indexer::Interface::Null;
use strict;
use warnings;

use Log::Log4perl;

use parent qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28_11';

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

=head1 NAME

MyCPAN::Indexer::Interface::Null - Don't show anything

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Null

=head1 DESCRIPTION

This class doesn't show anything. It's a null interface.

=head2 Methods

=over 4

=item component_type

This is an interface type.

=cut

sub component_type { $_[0]->interface_type }

=item do_interface( $Notes )

Run the interface_callback until the C<Finished> note is true. Don't do
anything else.

=cut

sub do_interface
	{
	my( $self ) = @_;
	$logger->debug( "Calling do_interface" );

	while( 1 )
		{
		last if $self->get_note('Finished');

		$self->get_note('interface_callback')->();
		}

	my $collator = $self->get_coordinator->get_note( 'collator' );
	$collator->() if ref $collator eq ref sub {};
	}

=back

=head1 SEE ALSO

MyCPAN::Indexer

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
