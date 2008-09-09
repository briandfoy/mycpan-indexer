package MyCPAN::Indexer::Worker;
use strict;
use warnings;

use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl qw(:easy);
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
hands a disribution too.

=head2 Methods

=over 4

=item get_task( $Config )


=cut
   
sub get_task
	{
	my( $class, $Notes ) = @_;
	
	sub {
		my $dist = shift;
		
		my $basename = $class->_check_for_previous_result( $dist, $Notes );
		return unless $basename;
		
		my $Config = $Notes->{config};
		
		INFO( "Child [$$] processing $dist\n" );
			
		my $Indexer = $Config->indexer_class || 'MyCPAN::Indexer';
		
		eval "require $Indexer" or die;
		
		unless( chdir $Config->temp_dir )
			{
			ERROR( "Could not change to " . $Config->temp_dir . " : $!\n" );
			exit 255;
			}
	
		# XXX: this should be configurable
		my $yml_dir       = catfile( $Config->report_dir, "meta"        );
		my $yml_error_dir = catfile( $Config->report_dir, "meta-errors" );

		my $out_dir = $yml_error_dir;
		
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm( $Config->alarm || 15 );
		my $info = eval { $Indexer->run( $dist ) };
	
		unless( defined $info )
			{
			ERROR( "run failed: $@" );
			return;
			}
		elsif( eval { $info->run_info( 'completed' ) } )
			{
			$out_dir = $yml_dir;
			}
		else
			{
			ERROR( "$basename did not complete\n" );
			if( my $bad_dist_dir = $Config->copy_bad_dists )
				{
				my $dist_file = $info->dist_info( 'dist_file' );
				my $basename  = $info->dist_info( 'dist_basename' );
				my $new_name  = catfile( $bad_dist_dir, $basename );
				
				unless( -e $new_name )
					{
					DEBUG( "Copying bad dist" );
					open my($in), "<", $dist_file;
					open my($out), ">", $new_name;
					while( <$in> ) { print { $out } $_ }
					close $in;
					close $out;
					}
				}	
			}
			
		alarm 0;
				
		$class->_add_run_info( $info, $Notes );
		
		my $out_path = catfile( $out_dir, "$basename.yml" );
		
		open my($fh), ">", $out_path or die "Could not open $out_path: $!\n";
		print $fh Dump( $info );
		
		DEBUG( "Child [$$] process done" );
		
		1;
		};
		
	}
	
sub _check_for_previous_result
	{	
	my( $class, $dist, $Notes ) = @_;
	
	my $Config = $Notes->{config};
	
	( my $basename = basename( $dist ) ) =~ s/\.(tgz|tar\.gz|zip)$//;

	my $yml_dir       = catfile( $Config->report_dir, "meta"        );
	my $yml_error_dir = catfile( $Config->report_dir, "meta-errors" );
	
	my $yml_path       = catfile( $yml_dir,       "$basename.yml" );
	my $yml_error_path = catfile( $yml_error_dir, "$basename.yml" );
	
	if( my @path = grep { -e } ( $yml_path, $yml_error_path ) )
		{
		DEBUG( "Found run output for $basename in $path[0]. Skipping...\n" );
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

1;