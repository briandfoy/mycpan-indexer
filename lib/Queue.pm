package MyCPAN::Indexer::Queue;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.21';

use File::Basename;
use File::Find;
use File::Find::Closures qw( find_by_regex );
use File::Path qw(mkpath);
use File::Spec::Functions qw( catfile rel2abs );
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

If the C<organize_dists> configuration value is true, it also copies
any distributions it finds into a PAUSE-like structure using the
value of the C<pause_id> configuration to create the path.

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

	if( $Notes->{config}->get( 'organize_dists' ) )
		{
		_setup_organize_dists( $Notes );

		foreach my $i ( 0 .. $#{ $Notes->{queue} } )
			{
			my $file = $Notes->{queue}[$i];
			$logger->debug( "Processing $file" );
			next if $file =~ m|authors/id/./../.*?/|;
			$logger->debug( "Copying $file into PAUSE structure" );

			$Notes->{queue}[$i] = _copy_file( $file, $Notes );
			}
		}

	1;
	}

sub _setup_organize_dists
	{
	my( $Notes ) = @_;

	my $pause_id = eval { $Notes->{config}->get( 'pause_id' ) } || 'MYCPAN';

	my @parts = _path_parts( $pause_id );

	mkpath _path_parts( $pause_id ), { mode => 0775 };
	$logger->error( "Could not create PAUSE author path for [$pause_id]: $!" )
		if $!;

	1;
	}

sub _path_parts
	{
	catfile (
		qw(authors id),
		substr( $_[0], 0, 1 ),
		substr( $_[0], 0, 2 ),
		$_[0]
		);
	}

# if there is an error with the rename, return the original file name
sub _copy_file
	{
	my( $file, $Notes ) = @_;

	my $pause_id = eval { $Notes->{config}->get( 'pause_id' ) } || 'MYCPAN';

	my $basename = basename( $file );
	$logger->debug( "Need to copy file $basename into $pause_id" );

	my $new_name = rel2abs(
		catfile( _path_parts( $pause_id ), $basename )
		);

	my $rc = rename $file => $new_name;
	$logger->error( "Could not rename [$file] to [$new_name]: $!" )
		unless $rc;

	return $rc ? $new_name : $file;
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

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
