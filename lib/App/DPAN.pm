package MyCPAN::App::DPAN;
use strict;
use warnings;

use base qw( MyCPAN::App::BackPAN::Indexer );
use vars qw($VERSION);

use Cwd qw(cwd);
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);

$VERSION = '1.18';

BEGIN {
my $cwd = cwd();

my $report_dir = catfile( $cwd, 'indexer_reports' );

my %Defaults = (
	indexer_class         => 'MyCPAN::Indexer::DPAN',
	reporter_class        => 'MyCPAN::Indexer::DPAN',
	parallel_jobs         => 1,
	);

sub default 
	{ 
	exists $Defaults{ $_[1] } 
		?
	$Defaults{ $_[1] } 
		:
	$_[0]->SUPER::default( $_[1] );
	}
}

1;
