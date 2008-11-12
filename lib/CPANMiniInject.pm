package MyCPAN::Indexer::Worker;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.17_08';

use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use MyCPAN::Indexer;
use YAML;

=head1 NAME

MyCPAN::Indexer::CPANMiniInject - Do the indexing, and put the dists in a MiniCPAN

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	worker_class  MyCPAN::Indexer::CPANMiniInject

=head1 DESCRIPTION

This class takes a distribution and analyses it. Once it knows the modules
inside the distribution, it adds the distribution to a CPAN::Mini::Inject
staging repository. This portion specifically does not inject the modules
into the MiniCPAN. The injection has to happen after all of the workers
have finished.

=head2 Configuration

=over 4

=item minicpan_inject_config

The location of the configuration file for CPAN::Mini::Config

=cut

=head2 Methods

=over 4

=item get_task( $Notes )

C<get_task> sets the C<child_task> key in the C<$Notes> hash reference. The
value is a code reference that takes a distribution path as its only
argument and indexes that distribution.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_task> expects
and should do.

=cut

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Worker' );
	}

sub get_task
	{
	my( $class, $Notes ) = @_;

	$Notes->{child_task} = sub {
		my $dist = shift;

		my $basename = $class->_check_for_previous_result( $dist, $Notes );
		return unless $basename;

		my $Config = $Notes->{config};

		$logger->info( "Child [$$] processing $dist\n" );

		my $Indexer = $Config->indexer_class || 'MyCPAN::Indexer';

		eval "require $Indexer" or die;

		unless( chdir $Config->temp_dir )
			{
			$logger->error( "Could not change to " . $Config->temp_dir . " : $!\n" );
			exit 255;
			}

		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm( $Config->alarm || 15 );
		my $info = eval { $Indexer->run( $dist ) };

		unless( defined $info )
			{
			$logger->error( "run failed: $@" );
			return;
			}
		elsif( ! eval { $info->run_info( 'completed' ) } )
			{
			$logger->error( "$basename did not complete\n" );
			$class->_copy_bad_dist( $Notes, $info ) if $Config->copy_bad_dists;
			}

		alarm 0;

		$class->_add_run_info( $info, $Notes );

		$Notes->{reporter}->( $Notes, $info );

		$logger->debug( "Child [$$] process done" );

		1;
		};

	}

sub _copy_bad_dist
	{
	my( $class, $Notes, $info ) = @_;

	if( my $bad_dist_dir = $Notes->{config}->copy_bad_dists )
		{
		my $dist_file = $info->dist_info( 'dist_file' );
		my $basename  = $info->dist_info( 'dist_basename' );
		my $new_name  = catfile( $bad_dist_dir, $basename );

		unless( -e $new_name )
			{
			$logger->debug( "Copying bad dist" );

			my( $in, $out );

			unless( open $in, "<", $dist_file )
				{
				$logger->fatal( "Could not open bad dist to $dist_file: $!" );
				return;
				}

			unless( open $out, ">", $new_name )
				{
				$logger->fatal( "Could not copy bad dist to $new_name: $!" );
				return;
				}

			while( <$in> ) { print { $out } $_ }
			close $in;
			close $out;
			}
		}
	}

sub _check_for_previous_result
	{
	my( $class, $dist, $Notes ) = @_;

	my $Config = $Notes->{config};

	( my $basename = basename( $dist ) ) =~ s/\.(tgz|tar\.gz|zip)$//;

	my $yml_dir        = catfile( $Config->report_dir, "meta"        );
	my $yml_error_dir  = catfile( $Config->report_dir, "meta-errors" );

	my $yml_path       = catfile( $yml_dir,       "$basename.yml" );
	my $yml_error_path = catfile( $yml_error_dir, "$basename.yml" );

	if( my @path = grep { -e } ( $yml_path, $yml_error_path ) )
		{
		$logger->debug( "Found run output for $basename in $path[0]. Skipping...\n" );
		return;
		}

	return $basename;
	}

sub _add_run_info
	{
	my( $class, $info, $Notes ) = @_;

	my $Config = $Notes->{config};

	return unless eval { $info->can( 'set_run_info' ) };

	$info->set_run_info( $_, $Config->get( $_ ) )
		foreach ( $Config->directives );

	$info->set_run_info( 'uuid', $Config->UUID );

	$info->set_run_info( 'child_pid',  $$ );
	$info->set_run_info( 'parent_pid', getppid );

	$info->set_run_info( 'ENV', \%ENV );

	return 1;
	}

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

1;
