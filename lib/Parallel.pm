package MyCPAN::Indexer::Dispatch::Parallel;
use strict;
use warnings;

use vars qw($VERSION $logger);
$VERSION = '1.18_01';

use Log::Log4perl;

BEGIN {
	# override since Tk overrides exit and this needs the real exit
	no warnings 'redefine';
	use Parallel::ForkManager;

	sub Parallel::ForkManager::finish { my ($s, $x)=@_;
	  if ( $s->{in_child} ) {
		CORE::exit ($x || 0);
	  }
	  if ($s->{max_proc} == 0) { # max_proc == 0
		$s->on_finish($$, $x ,$s->{processes}->{$$}, 0, 0);
		delete $s->{processes}->{$$};
	  }
	  return 0;
	}
}

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Dispatcher' );
	}

=head1 NAME

MyCPAN::Indexer::Dispatch::Parallel - Pass out work to sub-processes

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the queue class:

	# in backpan_indexer.config
	dispatch_class  MyCPAN::Indexer::Dispatch::Parallel

=head1 DESCRIPTION

This class takes the list of ditributions to process and passes them
out to the code that will do the work.

=head2 Methods

=over 4

=item get_dispatcher( $Vars )

Takes the $Vars hash and adds the C<dispatcher> key with a code
reference. This module uses C<Parallel::ForkManager> to run
jobs in parallel, and looks at the

It also sets up keys for PID, whose value is an anonymous array
of process IDs. That array matches up with the one in the key
C<recent> which keeps track of the distributions it's processing.
It adds:

	dispatcher => sub { ... },
	PID        => [],
	recent     => [],

=cut

sub get_dispatcher
	{
	my( $class, $Notes ) = @_;

	$Notes->{Threads}            = $Notes->{config}->parallel_jobs;
	$Notes->{dispatcher}         = $class->_make_forker( $Notes );
	$Notes->{interface_callback} = $class->_make_interface_callback( $Notes );
	}

sub _make_forker
	{
	my( $self, $Notes ) = @_;

	my $forker = Parallel::ForkManager->new(
		$Notes->{config}->parallel_jobs || 1 );

	$forker;
	}

sub _make_interface_callback
	{
	my( $class, $Notes ) = @_;

	foreach my $key ( qw(PID recent errors ) )
		{
		$Notes->{$key} = [ qw() ];
		}

	$Notes->{Total}        = scalar @{ $Notes->{queue} };
	$Notes->{Left}         = $Notes->{Total};
	$Notes->{Errors}       = 0;
	$Notes->{Done}         = 0;
	$Notes->{Started}      = scalar localtime;
	$Notes->{Finished}     = 0;

	$Notes->{queue_cursor} = 0;

	$Notes->{interface_callback} = sub {
		$class->_remove_old_processes( $Notes );

		$logger->debug( "Start: Finished: $Notes->{Finished} Left: $Notes->{Left}" );
		
		unless( $Notes->{Left} )
			{
			$logger->debug( "Waiting on all children [" . time . "]" );
			$Notes->{dispatcher}->wait_all_children;
			$Notes->{Finished} = 1;
			return;
			};

		$Notes->{_started} ||= time;

		$Notes->{_elapsed} = time - $Notes->{_started};
		$Notes->{Elapsed}  = _elapsed( $Notes->{_elapsed} );

		my $item = ${ $Notes->{queue} }[ $Notes->{queue_cursor}++ ];

		if( my $pid = $Notes->{dispatcher}->start )
			{ #parent

			unshift @{ $Notes->{PID} }, $pid;
			unshift @{ $Notes->{recent} }, $item;

			$Notes->{Done}++;
			$Notes->{Left} = $Notes->{Total} - $Notes->{Done};
			$logger->debug( "Total: $Notes->{Total} Done: $Notes->{Done} Left: $Notes->{Left} Finished: $Notes->{Finished}" );
			
			no warnings;
			$Notes->{Rate} = sprintf "%.2f / sec ",
				eval { $Notes->{Done} / $Notes->{_elapsed} };

			}
		else
			{ # child
			$Notes->{child_task}( $item );
			$Notes->{dispatcher}->finish;
			$logger->error( "The child is still running!" )
			}

		1;
		};
	}

sub _remove_old_processes
	{
	my( $class, $Notes ) = @_;

	my @delete_indices = grep
		{ ! kill 0, $Notes->{PID}[$_] }
		0 .. $#{ $Notes->{PID} };

	foreach my $index ( reverse @delete_indices )
		{
		splice @{ $Notes->{recent} }, $index, 1;
		splice @{ $Notes->{PID} }, $index, 1;
		}
	}

BEGIN {
my %hash = ( days => 864000, hours => 3600, minutes => 60 );

sub _elapsed
	{
	my $seconds = shift;

	my @v;
	foreach my $key ( qw(days hours minutes) )
		{
		push @v, int( $seconds / $hash{$key} );
		$seconds -= $v[-1] * $hash{$key}
		}

	push @v, $seconds;

	sprintf "%dd %02dh %02dm %02ds", @v;
	}
}
1;

1;

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
