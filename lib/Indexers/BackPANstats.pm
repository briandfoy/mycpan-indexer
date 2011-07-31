package MyCPAN::Indexer::BackPANstats;
use strict;

use warnings;
no warnings;

use subs qw(get_caller_info);
use vars qw($VERSION $logger);
use base qw(MyCPAN::Indexer MyCPAN::Indexer::Component);

$VERSION = '1.28_10';

=head1 NAME

MyCPAN::Indexer::BackPANstats - Collect various stats about BackPAN activity

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

This module implements the indexer_class and reporter_class components
to allow C<backpan_indexer.pl> to collect stats on BackPAN.

It runs through the indexing and prints a report at the end of the run.

=cut

use Carp qw(croak);
use Cwd qw(cwd);

use Log::Log4perl;

BEGIN {
	$logger = Log::Log4perl->get_logger( __PACKAGE__ );
	}

__PACKAGE__->run( @ARGV ) unless caller;

=head2 Indexer class

=over 4

=item get_indexer()

A stand in for run_components later on.

=cut

sub get_indexer
	{
	my( $self ) = @_;

	1;
	}

sub class { __PACKAGE__ }

=item setup_run_info

Like C<setup_run_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The test census really just cares about statements in the test
files, so the details about the run aren't as interesting.

=cut

sub setup_run_info { 1 }

=item examine_dist_steps

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=cut

sub examine_dist_steps
	{
	my @methods = (
		#    method         error message           fatal
		[ 'collect_info',  "Could not get info!",    1 ],
		);
	}

=item collect_info

Given a distribution, unpack it, look at it, and report the findings.
It does everything except the looking right now, so it merely croaks.
Most of this needs to move out of run and into this method.

=cut

use CPAN::DistnameInfo;
sub collect_info
	{
	my $self = shift;
	my $d = CPAN::DistnameInfo->new( $self->{dist_info}{dist_file} );
	$self->set_dist_info( 'dist_name', $d->dist );
	$self->set_dist_info( 'dist_version', $d->version );
	$self->set_dist_info( 'maturity', $d->maturity );

	my @gmtime = gmtime( $self->dist_info( 'dist_date' ) );
	my( $year, $month, $day ) = @gmtime[ 5,4,3 ];
	$year += 1900;
	$month += 1;

	$self->set_dist_info(
		'yyyymmdd_gmt',
		sprintf '%4d%02d%02d', $year, $month, $day
		);

	$self->set_dist_info(
		'calendar_quarter',
		sprintf "%4dQ%d", $year, int( ($month - 1 ) / 3 ) + 1
		);

	1;
	}


=back

=head2 Reporter class

=over 4

=item get_reporter( $Notes )

C<get_reporter> sets the C<reporter> key in the C<$Notes> hash
reference. The value is a code reference that takes the information
collected about a distribution and counts the modules used in the test
files.

See L<MyCPAN::Indexer::Tutorial> for details about what
C<get_reporter> expects and should do.

$VAR1 = {
          'dist_date' => 1207928766,
          'dist_basename' => 'cpan-script-1.54.tar.gz',
          'maturity' => 'released',
          'dist_file' => '/Volumes/iPod/BackPAN/authors/id/B/BD/BDFOY/cpan-script-1.54.tar.gz',
          'dist_size' => 6281,
          'dist_author' => 'BDFOY',
          'dist_name' => 'cpan-script',
          'dist_md5' => '8053fa43edcdce9a90f78f878cbf6caf',
          'dist_version' => '1.54'
        };
=cut

sub check_for_previous_successful_result { 1 }
sub check_for_previous_error_result      { 0 }
sub final_words                          { sub { 1 } }

sub get_reporter {
	my $self = shift;

	my $reporter = sub {
		my( $info ) = shift;

		print join "\t", map { $info->{dist_info}{$_} }
			qw(
				dist_basename dist_name dist_date  yyyymmdd_gmt calendar_quarter
				dist_size dist_author maturity dist_version
				);
		print "\n";
		};

	$self->set_note( 'reporter', $reporter )
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

Copyright (c) 2010, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
