package MyCPAN::Indexer::Reporter::AsYAML;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.16_01';

use File::Basename;
use File::Spec::Functions qw(catfile);
use Log::Log4perl qw(:easy);
use YAML;

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

C<get_task> sets the C<child_task> key in the C<$Notes> hash reference. The
value is a code reference that takes a distribution path as its only 
argument and indexes that distribution.

See L<MyCPAN::Indexer::Tutorial> for details about what C<get_task> expects
and should do.

=cut		my $out_path = catfile( $out_dir, "$basename.yml" );
		

{
my $yml_dir       = catfile( $Config->report_dir, "meta"        );
my $yml_error_dir = catfile( $Config->report_dir, "meta-errors" );

sub get_reporter
	{
	TRACE( sub { get_caller_info } );

	my( $Notes, $info ) = @_;

	$Notes->{reporter} = sub {
		my( $Notes, $info ) = @_;
		
		my $out_dir  = $info->{completed} ? $yml_dir : $yml_error_dir;
		
		my $out_path = catfile( $out_dir, "$basename.yml" );

		open my($fh), ">", $out_path or FATAL( "Could not open $out_path: $!" );
		print $fh Dump( $info );
		
		};
		
	1;
	}

}