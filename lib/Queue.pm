package MyCPAN::Indexer::Queue;
use strict;
use warnings;

use File::Find;
use File::Find::Closures qw( find_by_regex );
use Log::Log4perl qw(:easy);

=head1 NAME

MyCPAN::Indexer::Queue - Find distributions to index

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	queue_class  MyCPAN::Indexer::Queue

=head1 DESCRIPTION

This class returns a list of Perl distributions for the BackPAN
indexer to process.

=head2 Methods

=over 4

=item get_queue( $Config )

This class returns a copy of @ARGV, or finds all of the tarballs or zip
archives in under the directory named in C<backpan_dir> in the configuration.
The F<backpan_indexer.pl> script passes the configuration object as the 
first argument. It returns an array reference of file paths.

=cut

sub get_queue
	{
	my( $class, $Config ) = @_;
	
	if( @ARGV ) 
		{
		DEBUG( "Taking dists from command line" );
		[ @ARGV ]
		}
	else 
		{
		DEBUG( "Taking dists from " . $Config->backpan_dir );
		my( $wanted, $reporter ) = find_by_regex( qr/\.(t?gz|zip)$/ );
		
		find( $wanted, $Config->backpan_dir );
		[ $reporter->() ];
		}
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