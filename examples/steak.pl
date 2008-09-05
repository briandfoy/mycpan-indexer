#!/usr/bin/perl
use strict;
use warnings;

sub child_task
	{
#	print "$$: Processing... sleeping $_[0]\n";
	sleep shift;
	}
   
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my $Vars = { 
	Threads  =>  5,
	Total    => 50,
	Started  => scalar localtime,
	_started => time,
	UUID     => 'asdfasfgadsfgadfgdfsg',
	recent   => [ qw() ],
	PID      => [ qw() ],
	errors   => [ qw() ],
	child_task => sub { &child_task },
	};

$Vars->{Left} = $Vars->{Total};

make_forker( $Vars );
make_repeat_callback( $Vars );
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
require 'tk.pl';

do_tk_stuff( $Vars );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
BEGIN {
	no warnings 'redefine';
	
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

BEGIN {
my %hash = ( days => 864000, hours => 3600, minutes => 60 );

sub elapsed
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

sub make_forker
	{
	my $Vars = shift;
	
	require Parallel::ForkManager;

	$Vars->{forker} = Parallel::ForkManager->new( $Vars->{Threads} );
	$Vars->{forker}->run_on_finish( sub { 
		my $pid = shift;
		
		my( $index ) = grep { $Vars->{PID}[$_] == $pid } 0 .. $#{ $Vars->{PID} };
		
		splice( @{ $Vars->{PID} }, $index, 1 );
		splice( @{ $Vars->{recent} }, $index, 1 );
		}
		);	

	}
	
sub make_repeat_callback
	{
	my $Vars = shift;
	
	$Vars->{repeat_callback} = sub {
		return unless $Vars->{Left};
		
		$Vars->{_elapsed} = time - $Vars->{_started};
		$Vars->{Elapsed} = elapsed( $Vars->{_elapsed} );
	
		my $sleep_time = int rand 5;
		
		if( my $pid = $Vars->{forker}->start )
			{ #parent
			unshift @{ $Vars->{PID} }, $pid;
			unshift @{ $Vars->{recent} }, "$pid: Sleeping for $sleep_time seconds";
			
			$Vars->{Done}++;
			$Vars->{Left} = $Vars->{Total} - $Vars->{Done};
			
			$Vars->{Rate} = sprintf "%.2f / sec ", 
				eval { $Vars->{Done} / $Vars->{_elapsed} };
			
			if( int(rand(100)) % 20 == 0 )
				{
				unshift @{ $Vars->{errors} }, $Vars->{recent}[0];
				$Vars->{Errors}++;
				}
			
			}
		else
			{ # child
			$Vars->{child_task}( $sleep_time );
			$Vars->{forker}->finish;
			}
	
		1;
		};
	}
