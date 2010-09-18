package MyCPAN::Indexer::Queue::FromList;
use strict;
use warnings;

use base qw(MyCPAN::Indexer::Queue);
use vars qw($VERSION $logger);
$VERSION = '1.28_10';

use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Queue' );
	}

=head1 NAME

MyCPAN::Indexer::Queue::FromList - Try to index distributions listed in a file

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	queue_class  MyCPAN::Indexer::Queue::FromList

=head1 DESCRIPTION

This class returns a list of Perl distributions for the BackPAN
indexer to process. It selects the distributions that had previous 
indexing errors by extracting the distribution path from the error
report. If the distribution isn't in the same place it was during
the original indexing, it won't be in the queue.

=over

=item component_type

This is a queue type

=cut

sub component_type { $_[0]->queue_type }

sub _get_file_list
	{
	my( $self ) = @_;
	
	my $file = $self->get_config->distribution_list;
	$logger->debug( "Taking dists from [$file]" );
	$logger->error( "Distribution file [$file] does not exist" )
		unless -e $file;

	chomp( my @files = do { local( @ARGV ) = $file; <> } );
	$logger->debug( "Found " . @files . " error reports" );
	
	my @queue;
	foreach my $file ( @files )
		{
		$logger->debug( "Looking for distribution [$file]" );
		if( -e $file )
			{
			push @queue, $file;
			}
		else
			{
			$logger->error( "Could not find [$file]: not adding to queue" );
			}
		}

	return \@queue;
	}
	
1;

=back

=head1 SEE ALSO

MyCPAN::Indexer, MyCPAN::Indexer::Tutorial, MyCPAN::Indexer::Queue

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
