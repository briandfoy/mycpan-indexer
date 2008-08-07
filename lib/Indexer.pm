#!/usr/bin/perl

package MyCPAN::Indexer;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.10_01';

=head1 NAME

MyCPAN::Indexer - Index a Perl distribution

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

=cut

use Cwd;
use Data::Dumper;
use File::Basename;
use MD5;
use File::Path;
use Log::Log4perl qw(:easy);

use Distribution::Guess::BuildSystem;
use Module::Extract::Namespaces;
use Module::Extract::Version;


__PACKAGE__->run( @ARGV ) unless caller;

sub run 
	{
	my $class = shift;
	
	my $self = bless { dist_info => {} }, $class;
		
	$self->set_run_info( 'root_working_dir', cwd() );
	$self->set_run_info( 'run_start_time', time );
	$self->set_run_info( 'completed', 0 );
	$self->set_run_info( 'pid', $$ );
	$self->set_run_info( 'ppid', getppid );
	
	my $count = 0;
	
	DIST: foreach my $dist ( @_ )
		{
		DEBUG( "Dist is $dist\n" );

		unless( -e $dist )
			{
			ERROR( "Could not find [$dist]" );
			next;
			}
			
		$self->clear_dist_info;
		
		INFO( "Processing $dist\n" );
		
		$self->set_dist_info( 'dist', $dist );
		$self->set_dist_info( 'dist_basename', basename($dist) );
		$self->set_dist_info( 'dist_mtime', (stat($dist))[9] );
		
		my( undef, undef, $author ) = $dist =~ m|/([A-Z])/\1([A-Z])/(\1\2[A-Z]+)/|;
		$self->set_dist_info( 'dist_author', $author );
		
		$self->unpack_dist( $dist ) or next;

		unless( my $found_dist_dir = $self->find_dist_dir )
			{
			ERROR( "Did not find distro directory!" );
			$self->set_run_info( 'fatal_error: Could not find distro directory' );
			next;
			}
		
		my $dist_dir = $self->dist_info( 'dist_dir' );
		DEBUG( "Dist dir is $dist_dir\n" );
		
		unless( $self->get_file_list )
			{
			ERROR( "Could not get file list from MANIFEST" );
			$self->set_run_info( 'fatal_error: Could not get file list' );
			next;
			}
		
		$self->parse_meta_files;

		$self->run_build_file;
		
		unless( $self->get_blib_file_list )
			{
			ERROR( "Could not get file list from blib" );
			$self->set_run_info( 'fatal_error: Could not get file list for blib' );
			next;
			}
		
		my @modules = grep /\.pm$/, @{  $self->dist_info( 'blib' ) };
		DEBUG( "Modules are @modules\n" );
		
		my @file_info = ();
		foreach my $file ( @modules )
			{
			DEBUG( "Processing module $file\n" );
			my $hash = $self->get_module_info( $file );
			push @file_info, $hash;
			}
		
		$self->set_dist_info( 'file_info', [ @file_info ] );

		INFO( "Finished processing $dist\n" );
		DEBUG( Dumper( $self ) );
		
		#$self->report_dist_info;

		$self->set_run_info( 'completed', 1 );
		$self->set_run_info( 'run_end_time', time );
		}
		
	$self;
	}
	
sub examine
	{
	my( $class, $dist ) = @_;
	
	my $self = bless {}, $class;
	
	ERROR( "Could not find dist file [$dist]" )
		unless -e $dist;
	
	$self->set_dist( $dist );
	
	$self->unpack_dist( $dist );
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# from here things get dangerous because we have to run some code
=pod

	get_file_list
	
	if get_yaml
		filter file_list based on no_index, private
	
	get file mod time
	
	foreach file
		find $VERSION line not in POD
		
		wrap version in safe package
	
			run and capture version string
	
			record pm, version, dist
=cut

	# things aren't so dangerous anymore
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	
	#$self->cleanup;
	
	$self->report_findings;
	
	}

sub set_dist 
	{ 
	my $self = shift;
	my $dist = shift;
	
	if( @_ )
		{
		DEBUG( "Setting dist [$dist]\n" );
		$self->{dist_file} = $dist;
		$self->{dist_size} = -s $dist;
		$self->{dist_date} = (stat $dist)[9];
		DEBUG( "dist size [$self->{dist_size}] dist date [$self->{dist_date}]\n" );
		}
		
	return 1;
	}

sub dist_file { $_[0]->{dist_file} }
sub dist_size { $_[0]->{dist_size} }
sub dist_date { $_[0]->{dist_date} }

sub set_run_info 
	{ 
	my( $self, $key, $value ) = @_;
	
	DEBUG( "Setting run_info key [$key] to [$value]\n" );
	$self->{run_info}{$key} = $value;
	}

sub run_info 
	{ 
	my( $self, $key ) = @_;
	
	DEBUG( "Getting run_info key [$key]\n" );
	DEBUG( "Value for $key is " . $self->{run_info}{$key} );
	$self->{run_info}{$key};
	}

sub clear_dist_info 
	{ 
	my( $self, $key) = @_;
	
	DEBUG( "Clearing dist_info\n" );
	$self->{dist_info} = {};
	}

sub set_dist_info 
	{ 
	my( $self, $key, $value ) = @_;
	
	DEBUG( "Setting dist_info key [$key] to [$value]\n" );
	$self->{dist_info}{$key} = $value;
	}
	
sub dist_info 
	{ 
	my( $self, $key ) = @_;
	
	#print STDERR Dumper( $self );
	DEBUG( "Getting dist_info key [$key]\n" );
	DEBUG( "Value for $key is " . $self->{dist_info}{$key} );
	$self->{dist_info}{$key};
	}
	
sub unpack_dist 
	{ 	
	require Archive::Extract;
	require File::Temp;

	my $self = shift;
	my $dist = shift;
	
	( my $prefix = __PACKAGE__ ) =~ s/::/-/g;
	
	DEBUG( "Preparing temp dir in pid [$$]\n" );
	my $unpack_dir = eval { File::Temp::tempdir(
		$prefix . "-$$.XXXX",
		DIR     => $self->run_info( 'root_working_dir' ),
		CLEANUP => 1,
		) }; 

	if( $@ )
		{
		DEBUG( "Temp dir errorfor pid [$$] [$@]" );
		exit;
		}
		
	DEBUG( "Unpacking into directory [$unpack_dir]" );

	$self->set_dist_info( 'unpack_dir', $unpack_dir );
	
	my $extractor = eval { 
		Archive::Extract->new( archive => $dist ) 
		};
	if( defined $@ and $@ )
		{
		ERROR( "Could not unpack [$dist]: $@" );
		$self->set_dist_info( 'dist_archive_type', 'unknown' );		
		return;
		}
		
	$self->set_dist_info( 'dist_archive_type', $extractor->type );
	
	my $rc = $extractor->extract( to => $unpack_dir );
	DEBUG( "Archive::Extract returns [$rc]" );

	$extractor->extract_path;		
	}

sub find_dist_dir
	{
	DEBUG( "Cwd is " . $_[0]->dist_info( "unpack_dir" ) );
	
	if( -e 'MANIFEST' )
		{
		$_[0]->set_dist_info( $_[0]->dist_info( "unpack_dir" ) );
		return 1;
		}

	require File::Find::Closures;
	require File::Find;

	DEBUG( "Did not find MANIFEST at top level" );
	my( $wanted, $reporter ) = File::Find::Closures::find_by_name( 'MANIFEST' );
	
	File::Find::find( $wanted, $_[0]->dist_info( "unpack_dir" ) );
	
	my( $first ) = $reporter->();
	DEBUG( "Found manifest in $first" );
	
	unless( $first )
		{
		DEBUG( "Didn't find MANIFEST anywhere!" );
		return;
		}
		
	my $dir = eval { dirname( $first ) };
	DEBUG( "Found MANIFEST at $dir" );
	
	if( chdir $dir )
		{
		DEBUG "Changed to $dir";
		$_[0]->set_dist_info( 'dist_dir', $dir );
		return 1;
		}
	exit;	
	return;
	}
	
sub get_file_list
	{
	my $self = shift;
	
	unless( -e 'Makefile.PL' or -e 'Build.PL' )
		{
		ERROR( "No Makefile.PL or Build.PL" );
		$self->set_dist_info( 'manifest', [] );

		return;
		}
	
	require ExtUtils::Manifest;
	
	my $manifest = [ sort keys %{ ExtUtils::Manifest::manifind() } ];
	
	$self->set_dist_info( 'manifest', $manifest );
	}

sub get_blib_file_list
	{
	my $self = shift;

	unless( -d 'blib/lib' )
		{
		ERROR( "No blib/lib found!" );
		$self->set_dist_info( 'blib', [] );

		return;
		}

	require ExtUtils::Manifest;
	
	my $blib = [ grep { m|^blib/| and ! m|.exists$| } 
		sort keys %{ ExtUtils::Manifest::manifind() } ];
	
	$self->set_dist_info( 'blib', $blib );
	}
	
sub parse_meta_files
	{
	my $self = shift;
	
	if( -e 'META.yml'  )
		{
		require YAML::Syck;
		my $yaml = YAML::Syck::LoadFile( 'META.yml' );
		$self->set_dist_info( 'META.yml', $yaml );
		}

	return 1;	
	}

sub run_build_file
	{
	my $self = shift;
	
	$self->choose_build_file;
	
	$self->setup_build;
	
	$self->run_build;
	
	return 1;	
	}

sub choose_build_file
	{
	require Distribution::Guess::BuildSystem;
	my $guesser = Distribution::Guess::BuildSystem->new(
		dist_dir => $_[0]->dist_info( 'dist_dir' )
		);

	$_[0]->set_dist_info( 
		'build_system_guess', 
		$guesser->just_give_me_a_hash 
		);
			
	my $file = eval { $guesser->preferred_build_file };
	DEBUG( "Build file is $file" );
	DEBUG( "At is $@" ) if $@;
	unless( defined $file )
		{
		ERROR( "Did not find a build file" );
		return;
		}

	$_[0]->set_dist_info( 'build_file', $file );
	
	return 1;
	}

sub setup_build
	{
	my $self = shift;
	
	my $file = $self->dist_info( 'build_file' );
	
	my $command = "$^X $file";
	
	$self->run_something( $command, 'build_file_output' );	
	}
	
sub run_build
	{
	my $self = shift;

	my $file = $self->dist_info( 'build_file' );

	my $command = $file eq 'Build.PL' ? "$^X ./Build" : "make";
			
	$self->run_something( $command, 'build_output' );
	}

sub run_something
	{
	my $self = shift;
	my( $command, $info_key ) = @_;
	
	{
	require IPC::Open2;
	DEBUG( "Running $command" );
	my $pid = IPC::Open2::open2( 
		my $read, 
		my $write, 
		"$command 2>&1 < /dev/null" 
		);
	
	close $write;
	
	{ 
	local $/; 
	my $output = <$read>; 
	$self->set_dist_info( $info_key, $output );
	}
		
	waitpid $pid, 0;
	}

	}

sub get_module_info
	{
	my( $self, $file ) = @_;
	DEBUG( "get_module_info called with [$file]\n" );
		
	# get file name as key
	my $hash = { name => $file };
	
	# file digest
	{
	my $context = MD5->new;
	$context->add( $file );
	$hash->{md5} = $context->hexdigest;
	}
	
	# mtime
	$hash->{mtime} = ( stat $file )[9];
	
	# file size
	$hash->{bytesize} = -s _;
	
	# version
	$hash->{version} = Module::Extract::VERSION->parse_version_safely( $file );
	
	# packages
	my @packages      = Module::Extract::Namespaces->from_file( $file );
	my $first_package = Module::Extract::Namespaces->from_file( $file );
	
	$hash->{packages} = [ @packages ];

	$hash->{primary_package} = $first_package;

	$hash;
	}
	
sub cleanup
	{
	my $self = shift;
	
	return 1;

	File::Path::rmtree(
		[
		$self->run_info( 'unpack_dir' )
		],
		0, 0
		);
		
	return 1;
	}

sub report_dist_info
	{
	no warnings 'uninitialized';
	my $self = shift;
	
	#print $self->dist_info( 'dist' ), "\n\t";
	
	my $module_hash = $self->dist_info( 'module_versions' );
	
	while( my( $k, $v ) = each %$module_hash )
		{
		print "$k => $v\n\t";
		}
	
	print "\n";
	}
	

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in CVS, as well as all of the previous releases.

	http://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
