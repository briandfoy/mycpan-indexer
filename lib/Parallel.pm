package MyCPAN::Indexer::Dispatch::Parallel;
use strict;
use warnings;

use Log::Log4perl qw(:easy);

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
   
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

sub get_dispatcher
	{
	my( $class, $Notes ) = @_;
	
	foreach my $key ( qw(PID recent errors ) )
		{
		$Notes->{$key} = [ qw() ];
		}
	
	$Notes->{Threads}    = $Notes->{config}->parallel_jobs;
	$Notes->{dispatcher} = $class->_make_forker( $Notes );
	$Notes->{Total}      = scalar @{ $Notes->{queue} };
	$Notes->{Left}       = $Notes->{Total};
	$Notes->{Errors}     = 0;
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
BEGIN {
	# override since Tk overrides exit and this needs the real exit
	no warnings 'redefine';
	use Parallel::ForkManager;

	package Parallel::ForkManager;
	
	sub finish { my ($s, $x)=@_;
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

sub _make_forker
	{
	my( $self, $Notes ) = @_;
	
	my $forker = Parallel::ForkManager->new( $Notes->{config}->parallel_jobs || 1 );

	# move this to interface side, and just loop through the process IDs
	# to remove those that aren't running anymore

=pod

$forker->run_on_finish( sub { 
		my $pid = shift;
		
		my( $index ) = grep { $Vars->{PID}[$_] == $pid } 0 .. $#{ $Vars->{PID} };
		
		splice( @{ $Vars->{PID} }, $index, 1 );
		splice( @{ $Vars->{recent} }, $index, 1 );
		}
		);	

=cut

	$forker;
	}

1;

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