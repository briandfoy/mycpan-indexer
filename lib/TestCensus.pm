#!/usr/bin/perl

package MyCPAN::Indexer::TestCensus;
use strict;

use warnings;
no warnings;

use subs qw(get_caller_info);
use vars qw($VERSION);
use base qw(MyCPAN::Indexer);

$VERSION = '0.15_02';

=head1 NAME

MyCPAN::Indexer::TestCensus - Count the Test modules used in test suites

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

This is the indexing component for a run that only wants to count the
Test:: modules used in a test suite. It inherits most things for
MyCPAN::Indexer, but overrides examine_dist to just index the test
files.

=cut

use Carp qw(croak);

use Log::Log4perl qw(:easy);

__PACKAGE__->run( @ARGV ) unless caller;

=over 4


=item examine_dist

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=cut

{
my @methods = (
	#    method                error message                  fatal
	[ 'find_tests',         "Could not find tests!",             0 ],
	);

sub examine_dist
	{
	TRACE( sub { get_caller_info } );

	foreach my $tuple ( @methods )
		{
		my( $method, $error, $die_on_error ) = @$tuple;

		unless( $_[0]->$method() )
			{
			ERROR( $error );
			if( $die_on_error ) # only if failure is fatal
				{
				ERROR( "Stopping: $error" );
				$_[0]->set_run_info( 'fatal_error', $error );
				return;
				}
			}
		}
	
	{
	my @file_info = ();
	foreach my $file ( @{ $_[0]->dist_info( 'tests' ) } )
		{
		DEBUG( "Processing test $file" );
		my $hash = $_[0]->get_test_info( $file );
		push @file_info, $hash;
		}

	$_[0]->set_dist_info( 'test_info', [ @file_info ] );
	}

	return 1;
	}
}

sub setup_run_info
	{
	TRACE( sub { get_caller_info } );

	require Config;
	
	my $perl = Probe::Perl->new;
	
	$_[0]->set_run_info( 'root_working_dir', cwd()   );
	$_[0]->set_run_info( 'run_start_time',   time    );
	$_[0]->set_run_info( 'completed',        0       );
	$_[0]->set_run_info( 'pid',              $$      );
	$_[0]->set_run_info( 'ppid',             getppid );

	$_[0]->set_run_info( 'indexer',          ref $_[0] );
	$_[0]->set_run_info( 'indexer_versions', $_[0]->VERSION );

	return 1;
	}


sub setup_dist_info
	{
	TRACE( sub { get_caller_info } );

	my( $self, $dist ) = @_;

	DEBUG( "Setting dist [$dist]\n" );
	$self->set_dist_info( 'dist_file',     $dist                   );
		
	return 1;
	}

=item report_dist_info

Write a nice report. This isn't anything useful yet. From your program,
take the object and dump it in some way.

=cut

sub report_dist_info
	{
	return 1;
	TRACE( sub { get_caller_info } );

	no warnings 'uninitialized';

	my $module_hash = $_[0]->dist_info( 'module_versions' );

	while( my( $k, $v ) = each %$module_hash )
		{
		print "$k => $v\n\t";
		}

	print "\n";
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
