package MyCPAN::Indexer::Queue;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.17_08';

use File::Find;
use File::Find::Closures qw( find_by_regex );
use File::Spec::Functions qw( rel2abs );
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
finds all of the tarballs or zip archives in under the directories
named in C<backpan_dir> in the configuration.

It specifically skips files that end in C<.txt.gz> or C<.data.gz>
since PAUSE creates those meta files near the actual module
installations.

=cut

sub get_queue
	{
	my( $class, $Notes ) = @_;

	my @dirs = do {
		my $item = $Notes->{config}->backpan_dir;
		ref $item ? @$item : $item;
		};

	foreach my $dir ( @dirs )
		{
		$logger->error( "backpan_dir directory does not exist: [$dir]" )
			unless -e $dir;
		}

	$logger->debug( "Taking dists from [@dirs]" );
	my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.(t?gz|zip)$/ );

	find( $wanted, @dirs );

	$Notes->{queue} = [
		map  { rel2abs($_) }
		grep { ! /.(data|txt).gz$/ }
		$reporter->()
		];

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
