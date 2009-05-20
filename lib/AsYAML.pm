package MyCPAN::Indexer::Reporter::AsYAML;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.21';

use Carp;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use YAML;

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Reporter' );
	}

=head1 NAME

MyCPAN::Indexer::Storage::AsYAML - Save the result as a YAML file

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	reporter_class  MyCPAN::Indexer::Reporter::AsYAML

=head1 DESCRIPTION

This class takes the result of examining a distribution and saves it.

=head2 Methods

=over 4

=item get_reporter( $Notes )

C<get_reporter> sets the C<reporter> key in the C<$Notes> hash reference. The
value is a code reference that takes the information collected about a distribution
and dumps it as a YAML file.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_reporter> expects
and should do.

=cut

sub get_reporter
	{
	#TRACE( sub { get_caller_info } );

	my( $class, $Notes ) = @_;

	$Notes->{reporter} = sub {
		my( $Notes, $info ) = @_;

		unless( defined $info )
			{
			$logger->error( "info is undefined!" );
			return;
			}

		my $dist = $info->dist_info( 'dist_file' );
		$logger->error( "Info doesn't have dist_name! WTF?" ) unless $dist;

		no warnings 'uninitialized';
		( my $basename = basename( $dist ) ) =~ s/\.(tgz|tar\.gz|zip)$//;

		my $out_dir_key  = $info->run_info( 'completed' ) ? 'success' : 'error';

		$out_dir_key = 'error' if grep { $info->run_info($_) }
			qw(error fatal_error);

		my $out_path = catfile(
			$Notes->{config}->get( "${out_dir_key}_report_subdir" ),
			"$basename.yml"
			);

		open my($fh), ">", $out_path or $logger->fatal( "Could not open $out_path: $!" );
		print $fh Dump( $info );

		$logger->error( "$basename.yml is missing!" ) unless -e $out_path;

		1;
		};

	1;
	}

=item final_words( $Notes )

Right before backpan_indexer.pl is about to finish, it calls this method to
give the reporter a chance to do something at the end. In this case it does
nothing.

=cut

sub final_words { 1 };

=back

=head1 TO DO

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
