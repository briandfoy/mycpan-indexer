package MyCPAN::Indexer::Interface::ShowDist;
use strict;
use warnings;

use Log::Log4perl;

use base qw(MyCPAN::Indexer::Component);
use vars qw($VERSION $logger);
$VERSION = '1.28_10';

=head1 NAME

MyCPAN::Indexer::Interface::ShowDist - Show dists as MyCPAN processes them

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::ShowDist

=head1 DESCRIPTION

This class presents the information as the indexer runs, using plain text.

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

	my $config = $self->get_config;
	
	my $i = $config->indexer_class;
	eval "require $i; 1";
	
	print join( " ", 
		$config->indexer_class, 
		$config->indexer_class->VERSION 
		),
		"\n";

	my $total = @{ $self->get_note('queue') };
	my $width = int( log($total)/log(10) + 1 );
	print "Processing $total distributions\n";

	my $count = 0;
	while( 1 )
		{
		last if $self->get_note('Finished');

		local $| = 1;

		my $info = $self->get_note('interface_callback')->();
		my $status = do {
			if( exists $info->{skipped} )    { 'skipped' }
			elsif( 0 )                       { 'error' }
			elsif( exists $info->{run_info}{completed} ) { 'completed' }
			};
			
		printf "[%*d/%d] %s %s\n", $width, ++$count, $total, 
			$info->{dist_info}{dist_basename} || '(unknown dist???)',
			$status;
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

Copyright (c) 2010, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
