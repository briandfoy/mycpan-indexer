package MyCPAN::Indexer::Interface::Null;
use strict;
use warnings;

use Log::Log4perl;

use base qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28_10';

=head1 NAME

MyCPAN::Indexer::Interface::Null - Don't show anything

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Null

=head1 DESCRIPTION

This class doesn't show anything

=head2 Methods

=over 4

=item do_interface( $Notes )

=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

sub component_type { $_[0]->interface_type }

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
	$collator->();
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

Copyright (c) 2008-2010, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
