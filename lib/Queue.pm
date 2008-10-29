package MyCPAN::Indexer::Queue;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.17_02';

use File::Find;
use File::Find::Closures qw( find_by_regex );
use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Queue' );
	}

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

=item get_queue( $Notes )

C<get_queue> sets the key C<queue> in C<$Notes> hash reference. It
sets it to a copy of @ARGV, or finds all of the tarballs or zip
archives in under the directory named in C<backpan_dir> in the
configuration. 

It specifically skips files that end in C<.txt.gz> or C<.data.gz>
since PAUSE creates those meta files near the actual module
installations.

=cut

sub get_queue
	{
	my( $class, $Notes ) = @_;
	
	$Notes->{queue} = do {
		if( @ARGV ) 
			{
			$logger->debug( "Taking dists from command line" );
			[ @ARGV ]
			}
		else 
			{
			$logger->debug( "Taking dists from " . $Notes->{config}->backpan_dir );
			my( $wanted, $reporter ) = find_by_regex( qr/\.(t?gz|zip)$/ );
			
			unless( -e $Notes->{config}->backpan_dir )
				{
				$logger->fatal( "Directory does not exist: " . $Notes->{config}->backpan_dir ); 
				no warnings; [];
				}
				
			find( $wanted, $Notes->{config}->backpan_dir );
			[ grep ! /.(data|txt).gz$/, $reporter->() ];
			}
		};
		
	1;
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

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
