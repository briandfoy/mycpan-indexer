package MyCPAN::Indexer::Collator::Null;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.28_10';

use Carp;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use YAML;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Collator' );
	}

=head1 NAME

MyCPAN::Indexer::Collator::Null - A No-op reports processor

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the reporter class:

	# in backpan_indexer.config
	collator_class  MyCPAN::Indexer::Collator::Null

=head1 DESCRIPTION

This class is a stand in for a Collator that does something real. In the
normal run of a backpan index, there's nothing to create out of the set of
reports, so this example does nothing.

=head2 Methods

=over 4

=item component_type

=cut

sub component_type { $_[0]->collator_type }

=item get_collator( $Notes )

C<get_collator> sets the C<collator> key in the C<$Notes> hash reference. The
value is a code reference that takes the information collected about a distribution
and dumps it as a YAML file.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_collator> expects
and should do.

=cut

sub get_collator
	{
	#TRACE( sub { get_caller_info } );

	my( $self ) = @_;

	my $collator = sub { 1 };

	$self->set_note( $self->component_type, $collator );

	1;
	}

=back

=head1 TO DO

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
