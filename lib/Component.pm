package MyCPAN::Indexer::Component;
use strict;
use warnings;

use vars qw($VERSION);

use Carp qw(croak);

$VERSION = '1.28_07';

=head1 NAME

MyCPAN::Indexer::Component - base class for MyCPAN components

=head1 SYNOPSIS

	package MyCPAN::Indexer::NewComponent;
	
	use base qw(MyCPAN::Indexer::Component);
	

=head1 DESCRIPTION

This module implements features common to all C<MyCPAN::Indexer>
components. Each component is able to communicate with a coordinator
object to find out the results and notes left by other components.
Most of that delegation infrastructure is hidden since each component
can call methods on its own instances that this module dispatches
appropriately.

=cut

=head2 Methods

=over 4

=item new( [COORDINATOR] )

Create a new component object. This is mostly to have a place to 
store a reference to the coordinator object. See C<get_coordinator>.

=cut

sub component_type { croak "Component classes must implement component_type" }

sub new
	{
	my( $class, $coordinator ) = @_;
	
	my $self = bless {}, $class;
	
	if( defined $coordinator )
		{
		$self->set_coordinator( $coordinator );
		$coordinator->set_note( $self->component_type, $self );
		}
		
	$self;
	}

=item get_coordinator

Get the coordinator object. This is the object that coordinates all of the
components. Each component communicates with the coordinator and other
components can see it.

=cut

sub get_coordinator { $_[0]->{_coordinator} }

=item set_coordinator( $coordinator )

Set the coordinator object. C<new> already does this for you if you pass it a 
coordinator object. Each component expects the cooridnator object to respond
to these methods:

	get_info
	set_info
	get_note
	set_note
	get_config
	set_config
	increment_note
	decrement_note
	push_onto_note
	unshift_onto_note
	get_note_list_element
	set_note_unless_defined


=cut

BEGIN {

my @methods_to_dispatch_to_coordinator = qw(
	get_info
	set_info
	get_note
	set_note
	get_config
	set_config
	increment_note
	decrement_note
	push_onto_note
	unshift_onto_note
	get_note_list_element
	set_note_unless_defined
	);

	
foreach my $method ( @methods_to_dispatch_to_coordinator )
	{
	no strict 'refs';
	*{$method} = sub {
		my $self = shift;
		$self->get_coordinator->$method( @_ );
		}
	}

sub set_coordinator 
	{ 
	my( $self, $coordinator ) = @_;
	
	my @missing = grep { ! $coordinator->can( $_ ) } @methods_to_dispatch_to_coordinator;
	
	croak "Coordinator object is missing these methods: @missing"
		if @missing;
		
	$self->{_coordinator} = $coordinator
	}
	
}

sub collator_type   { 'collator'   }
sub dispatcher_type { 'dispatcher' }
sub indexer_type    { 'indexer'    }
sub interface_type  { 'interface'  }
sub queue_type      { 'queue'      }
sub reporter_type   { 'reporter'   }
sub worker_type     { 'worker'     }

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2010, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
