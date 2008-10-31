package MyCPAN::App::DPAN;
use base qw( MyCPAN::App::BackPAN::Indexer );
use vars qw($VERSION);

use Cwd qw(cwd);
use File::Spec::Functions qw(catfile);

$VERSION = '1.17_04';

BEGIN {
my $cwd = cwd();

my %Defaults = (
	report_dir       => catfile( $cwd, 'indexer_reports' ),
#	temp_dir         => catfile( $cwd, 'temp' ),
	alarm            => 15,
	copy_bad_dists   => 0,
	retry_errors     => 1,
	indexer_id       => 'Joe Example <joe@example.com>',
	system_id        => 'an unnamed system',
	indexer_class    => 'MyCPAN::Indexer::DPAN',
	queue_class      => 'MyCPAN::Indexer::Queue',
	dispatcher_class => 'MyCPAN::Indexer::Dispatch::Parallel',
	interface_class  => 'MyCPAN::Indexer::Interface::Text',
	worker_class     => 'MyCPAN::Indexer::Worker',
	reporter_class   => 'MyCPAN::Indexer::DPAN',
	parallel_jobs    => 1,
	);

sub default { $Defaults{$_[1]} }
}

1;
