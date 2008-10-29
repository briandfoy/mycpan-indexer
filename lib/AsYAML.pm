package MyCPAN::Indexer::Reporter::AsYAML;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.17_02';

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

	my $yml_dir       = catfile( $Notes->{config}->report_dir, "meta"        );
	my $yml_error_dir = catfile( $Notes->{config}->report_dir, "meta-errors" );

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

		my $out_dir  = $info->run_info( 'completed' ) ? $yml_dir : $yml_error_dir;

		my $out_path = catfile( $out_dir, "$basename.yml" );

		open my($fh), ">", $out_path or FATAL( "Could not open $out_path: $!" );
		print $fh Dump( $info );

		$logger->ERROR( "$basename.yml is missing!" ) unless -e $out_path;

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

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
