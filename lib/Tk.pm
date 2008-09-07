package MyCPAN::Indexer::Interface::Tk;

use Log::Log4perl qw(:easy);

=head1 NAME

MyCPAN::Indexer::Interface::Tk - Index a Perl distribution

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Tk

=head1 DESCRIPTION

This class runs the dispatcher and presents the information as the
indexer runs.

=head2 Methods

=over 4

=item do_interface( $Config )


=cut

sub do_interface
	{
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