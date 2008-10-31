package MyCPAN::Indexer::Worker;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.17_04';

use Cwd;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl;
use MyCPAN::Indexer;
use YAML;

=head1 NAME

MyCPAN::Indexer::Worker - Do the indexing

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	worker_class  MyCPAN::Indexer::Worker

=head1 DESCRIPTION

This class takes a distribution and analyses it. This is what the dispatcher
hands a disribution to for the actual indexing.

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

		$logger->info( "Child process for $basename starting\n" );

		my $Indexer = $Config->indexer_class || 'MyCPAN::Indexer';

		eval "require $Indexer" or die;

		my $starting_dir = cwd();
		
		unless( chdir $Config->temp_dir )
			{
			$logger->error( "Could not change to " . $Config->temp_dir . " : $!\n" );
			exit 255;
			}

		local $SIG{ALRM} = sub { die "alarm rang for $basename!\n" };
		alarm( $Config->alarm || 15 );
		my $info = eval { $Indexer->run( $dist ) };
		alarm 0;

		chdir $starting_dir;
		
		unless( defined $info )
			{
			$logger->error( "run failed for $basename: $@" );
			$info = bless {}, $Indexer; # XXX TODO make this a real class
			$info->setup_dist_info( $dist );
			$info->setup_run_info;
			$info->set_run_info( qw(completed 0) );
			$info->set_run_info( error => $@ );
			}
		elsif( ! eval { $info->run_info( 'completed' ) } )
			{
			$logger->error( "$basename did not complete\n" );
			$class->_copy_bad_dist( $Notes, $info ) if $Config->copy_bad_dists;
			}

		$class->_add_run_info( $info, $Notes );

		$Notes->{reporter}->( $Notes, $info );

		$logger->debug( "Child process for $basename done" );

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

	$info->set_run_info( 'uuid', $Notes->{UUID} );

	$info->set_run_info( 'child_pid',  $$ );
	$info->set_run_info( 'parent_pid', eval { $Config->indexer_class->getppid } );

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
