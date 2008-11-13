#!/usr/bin/perl

package MyCPAN::Indexer::DPAN;
use strict;

use warnings;
no warnings;

use subs qw(get_caller_info);
use vars qw($VERSION $indexer_logger $reporter_logger);
use base qw(MyCPAN::Indexer MyCPAN::Indexer::Reporter::AsYAML);

use File::Basename;
use File::Spec::Functions qw(catfile);
use File::Path;
use YAML;

$VERSION = '1.17_09';

=head1 NAME

MyCPAN::Indexer::DPAN - Create a D(ark)PAN out of the indexed distributions

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

This module implements the indexer_class and reporter_class components
to allow C<backpan_indexer.pl> to count the test modules used in the
indexed distributions. This application of MyCPAN::Indexer is 
specifically aimed at creating a 02packages.details file, so it 
strives to collect a minimum of information.

It runs through the indexing and prints a report at the end of the run.


=cut

use Carp qw(croak);
use Cwd qw(cwd);

use Log::Log4perl;

BEGIN {
	$indexer_logger  = Log::Log4perl->get_logger( 'Indexer' );
	$reporter_logger = Log::Log4perl->get_logger( 'Reporter' );
	}

__PACKAGE__->run( @ARGV ) unless caller;

=head2 Indexer class

=over 4

=item examine_dist_steps

Returns the list of techniques that C<examine_dist> should use
to index distributions. See the documentation in
C<MyCPAN::Indexer::examine_dist_steps>.

For DPAN, unpack the dist, ensure you are in the dist directory,
the find the modules.

=cut

sub examine_dist_steps
	{
	my @methods = (
		#    method                error message                  fatal
		[ 'unpack_dist',        "Could not unpack distribtion!",     1 ],
		[ 'find_dist_dir',      "Did not find distro directory!",    1 ],
		[ 'find_modules',       "Could not find modules!",           1 ],
		);
	}

=item find_modules_techniques

Returns the list of techniques that C<find_modules> should use
to look for Perl module files. See the documentation in
C<MyCPAN::Indexer::find_modules>.

=cut

sub find_module_techniques
	{
	my @methods = (
		[ 'look_in_lib',               "Guessed from looking in lib/"      ],
		[ 'look_in_cwd',               "Guessed from looking in cwd"       ],
		[ 'look_in_meta_yml_provides', "Guessed from looking in META.yml"  ],
		[ 'look_for_pm',               "Guessed from looking in cwd"       ],
		);
	}

=item get_module_info_tasks


=cut

sub get_module_info_tasks
	{
	(
	[ 'extract_module_namespaces',   'Extract the namespaces a file declares' ],
	[ 'extract_module_version',       'Extract the version of the module'     ],
	)
	}
	
=item setup_run_info

Like C<setup_run_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The DarkPAN census really just cares about finding packages,
so the details about the run aren't as interesting.

=cut

sub setup_run_info
	{
#	TRACE( sub { get_caller_info } );

	require Config;

	my $perl = Probe::Perl->new;

	$_[0]->set_run_info( 'root_working_dir', cwd()   );
	$_[0]->set_run_info( 'run_start_time',   time    );
	$_[0]->set_run_info( 'completed',        0       );
	$_[0]->set_run_info( 'pid',              $$      );
	$_[0]->set_run_info( 'ppid',             $_[0]->getppid );

	$_[0]->set_run_info( 'indexer',          ref $_[0] );
	$_[0]->set_run_info( 'indexer_versions', $_[0]->VERSION );

	return 1;
	}


=item setup_dist_info

Like C<setup_dist_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The test census really just cares about statements in the test
files, so the details about the distribution aren't as interesting.

=cut

sub setup_dist_info
	{
#	TRACE( sub { get_caller_info } );

	my( $self, $dist ) = @_;

	$indexer_logger->debug( "Setting dist [$dist]\n" );
	$self->set_dist_info( 'dist_file',     $dist                   );

	return 1;
	}

=back

=head2 Reporter class

=over 4

=item get_reporter( $Notes )

Inherited for MyCPAN::App::BackPAN::Indexer

=item final_words( $Notes )

C<get_reporter> sets the C<reporter> key in the C<$Notes> hash reference. The
value is a code reference that takes the information collected about a distribution
and counts the modules used in the test files.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_reporter> expects
and should do.

=cut

sub final_words
	{
	# This is where I want to write 02packages and CHECKSUMS
	my( $class, $Notes ) = @_;

	$reporter_logger->trace( "Final words from the DPAN Reporter" );

	my $report_dir = $Notes->{config}->success_report_subdir;
	$reporter_logger->debug( "Report dir is $report_dir" );

	opendir my($dh), $report_dir or
		$reporter_logger->fatal( "Could not open directory [$report_dir]: $!");


	my %dirs_needing_checksums;

	require CPAN::PackageDetails;
	my $package_details = CPAN::PackageDetails->new;

	require version;
	foreach my $file ( readdir( $dh ) )
		{
		next unless $file =~ /\.yml\z/;
		$reporter_logger->debug( "Processing output file $file" );
		my $yaml = eval { YAML::LoadFile( catfile( $report_dir, $file ) ) } or do {
			$reporter_logger->error( "$file: $@" );
			next;
			};

		my $dist_file = $yaml->{dist_info}{dist_file};
		
		#print STDERR "Dist file is $dist_file\n";
		
		# some files may be left over from earlier runs, even though the
		# original distribution has disappeared. Only index distributions
		# that are still there
		#my @backpan_dirs = @{ $Notes->{config}->backpan_dir };
		# check that dist file is in one of these directories
		next unless -e $dist_file; # && $dist_file =~ m/^\Q$backpan_dir/;
		
		my $dist_dir = dirname( $dist_file );
		
		$dirs_needing_checksums{ $dist_dir }++;

		foreach my $module ( @{ $yaml->{dist_info}{module_info} }  )
			{
			my $packages = $module->{packages};
			my $version  = $module->{version};
			$version = $version->numify if eval { $version->can('numify') };

			foreach my $package ( @$packages )
				{
				# broken crap that works on Unix and Windows to make cpanp
				# happy.
				( my $path = $dist_file ) =~ s/.*authors.id.//g;
				
				$path =~ s|\\+|/|g; # no windows paths.
				
				$package_details->add_entry(
					'package name' => $package,
					version        => $version,
					path           => $path,
					);
				}
			}
		}

	my $dir = do {
		my $d = $Notes->{config}->backpan_dir;
		ref $d ? $d->[0] : $d;
		};

	( my $packages_dir = $dir ) =~ s/authors.id.*//;
	$reporter_logger->debug( "package details directory is [$packages_dir]");

	my $index_dir     = catfile( $packages_dir, 'modules' );
	mkpath( $index_dir );

	my $packages_file = catfile( $index_dir, '02packages.details.txt.gz' );
	$reporter_logger->debug( "package details file is [$packages_file]");

	$package_details->write_file( $packages_file );

	$class->create_modlist( $index_dir );

	$class->create_checksums( [ keys %dirs_needing_checksums ] );

	}

=item create_package_details

=cut

sub create_package_details
	{
	my( $self, $index_dir ) = @_;
	
		
	1;
	}
	
=item create_modlist

=cut

sub create_modlist
	{
	my( $self, $index_dir ) = @_;
	
	my $module_list_file = catfile( $index_dir, '03modlist.data.gz' );
	$reporter_logger->debug( "modules list file is [$module_list_file]");

	if( -e $module_list_file )
		{
		$reporter_logger->debug( "File [$module_list_file] already exists" );
		return 1;
		}
		
	my $fh = IO::Compress::Gzip->new( $module_list_file );
	print $fh "This is just a placeholder so CPAN.pm is happy\n\t\t-- $0\n";
	close $fh;
	}
	
=item create_checksums


=cut

sub create_checksums
	{
	my( $self, $dirs ) = @_;
	
	require CPAN::Checksums;
	foreach my $dir ( @$dirs )
		{
        my $rc = eval{ CPAN::Checksums::updatedir( $dir ) };
		$reporter_logger->error( "Couldn't create CHECKSUMS for $dir: $@") unless $rc;
		$reporter_logger->info(
			do {
				if(    $rc == 1 ) { "Valid CHECKSUMS file is already present in $dir: skipping" }
				elsif( $rc == 2 ) { "Wrote new CHECKSUMS file in $dir" }
				else              { "updatedir unexpectedly returned true [$rc] for $dir" }
			} );
		}	
	}
	
=back

=head1 TO DO

=over 4

=item Count the lines in the files

=item Code stats? Lines of code, lines of pod, lines of comments

=back

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
