package MyCPAN::Indexer::Dispatch::Parallel;

use Log::Log4perl qw(:easy);

=head1 NAME

MyCPAN::Indexer::Dispatch::Parallel - Index a Perl distribution

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	dispatch_class  MyCPAN::Indexer::Dispatch::Parallel

=head1 DESCRIPTION

This class takes the list of ditributions to process and passes them
out to the code that will do the work. 

=head2 Methods

=over 4

=item get_dispatcher( $Config )

Returns a code reference that will do the work of passing out distributions
to the code that will do the work.

=cut

sub get_dispatcher
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