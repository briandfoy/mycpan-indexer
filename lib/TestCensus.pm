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

This module implements the indexer_class and reporter_class components
to allow C<backpan_indexer.pl> to count the test modules used in the
indexed distributions. 

It runs through the indexing and prints a report at the end of the run.
You probably

=cut

use Carp qw(croak);
use Cwd qw(cwd);
use DBM::Deep;
use File::Spec::Functions qw(catfile);
use Log::Log4perl qw(:easy);

__PACKAGE__->run( @ARGV ) unless caller;

=head2 Indexer class

=over 4

=item examine_dist

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=cut

{
my @methods = (
	#    method                error message                  fatal
	[ 'unpack_dist',        "Could not unpack distribtion!",     1 ],
	[ 'find_dist_dir',      "Did not find distro directory!",    1 ],
	[ 'find_tests',         "Could not find tests!",             0 ],
	);

sub examine_dist
	{
#	TRACE( sub { get_caller_info } );

	foreach my $tuple ( @methods )
		{
		my( $method, $error, $die_on_error ) = @$tuple;
		DEBUG( "examine_dist calling $method" );
		
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

=item setup_run_info

Like C<setup_run_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The test census really just cares about statements in the test
files, so the details about the run aren't as interesting.

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
	$_[0]->set_run_info( 'ppid',             getppid );

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

	DEBUG( "Setting dist [$dist]\n" );
	$self->set_dist_info( 'dist_file',     $dist                   );
		
	return 1;
	}

=back

=head2 Reporter class

=over 4

=item get_reporter( $Notes )

C<get_reporter> sets the C<reporter> key in the C<$Notes> hash reference. The
value is a code reference that takes the information collected about a distribution
and counts the modules used in the test files.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_reporter> expects
and should do.

=cut

{
sub get_reporter
	{
	#TRACE( sub { get_caller_info } );

	my( $class, $Notes ) = @_;

	my $dbm_file = catfile( $Notes->{config}->report_dir, "test_module_use.db" );
	unlink $dbm_file;
	
	DEBUG( "get_reporter DBM::Deep file is $dbm_file" );
	
	$Notes->{reporter} = sub {

		my( $Notes, $info ) = @_;
		
		my $test_files = $info->{dist_info}{test_info};
		DEBUG( "No test files in dist" ) unless @$test_files;
		
		my $db = DBM::Deep->new( 
			file    => $dbm_file, 
			locking => 1,
			);

		my $dist = $info->dist_info( 'dist_file' );

		$db->{dist_count}{$dist}++;		
		foreach my $test_file ( @$test_files )
			{
			my $uses = $test_file->{uses};
			DEBUG( "Found test modules @$uses" );
			
			foreach my $used_module ( @$uses )
				{
				next unless $used_module =~ m/^Test\b/;
				#local $SIG{__WARN__} = sub { print STDERR "get_reporter [$dist][$used_module]: ", @_;
				#WARN( "get_reporter [$dist][$used_module]: " . join '', @_ ) };
				$db->{dist}{$dist}{test_modules}{$used_module}++;
				$db->{test_modules}{$used_module}++;
				}
			}
		
		};
		
	1;
	}

}

sub final_words
	{	
	my( $class, $Notes ) = @_; 
	DEBUG( "Final words from the Reporter" );

	my $dbm_file = catfile( $Notes->{config}->report_dir, "test_module_use.db" );
	ERROR( "Could not find DBM file [$dbm_file]") unless -e $dbm_file;
	DEBUG( "final_words DBM::Deep file is $dbm_file" );
	
	my $db = DBM::Deep->new( 
		file    => $dbm_file, 
		locking => 1,
		);

	my $dist_count = keys %{ $db->{dist} };
	
	print "Found modules in $dist_count dists:\n";

	foreach my $module (
		sort { $db->{test_modules}{$b} <=> $db->{test_modules}{$a} 
			|| $a cmp $b } keys %{ $db->{test_modules} } )
		{
		printf "%6d %s\n", $db->{test_modules}{$module}, $module;
		}

	print "\n\nFound dists in $dist_count dists:\n";

	foreach my $dist (
		sort { $db->{dist_count}{$b} <=> $db->{dist_count}{$a} 
			|| $a cmp $b } keys %{ $db->{dist_count} } )
		{
		printf "%6d %s\n", $db->{dist_count}{$dist}, $dist;
		}

	}
	
=pod

foreach my $file ( glob "*.yml" )
	{
	my $yaml = LoadFile( $file );
	
	my $test_files = $yaml->{dist_info}{test_info};
	
	foreach my $test_file ( @$test_files )
		{
		my $uses = $test_file->{uses};
		
		foreach my $used_module ( @$uses )
			{
			$Seen{$used_module}++;
			}
		}
	}

=cut

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
