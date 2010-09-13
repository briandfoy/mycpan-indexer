	#!perl
	
	use Parallel::ForkManager;
	use POSIX;
	use Proc::ProcessTable;
	
	my $pm = Parallel::ForkManager->new( $ARGV[0] );
	
	my $alarm_sub = sub {
			kill 9,
				map  { $_->{pid} }
				grep { $_->{'ppid'} == $$ }
				@{ Proc::ProcessTable->new->table }; 
	
			die "Alarm rang for $dist_basename!\n";
			};
	
	foreach ( 0 .. $ARGV[1] ) 
		{
		print ".";
		print "\n" unless $count++ % 50;
		
		my $pid = $pm->start and next; 
		setpgrp(0, 0);
		
		local $SIG{ALRM} = $alarm_sub;
	
		eval {
			alarm( 2 );
			system "$^X -le '<STDIN>'";
			alarm( 0 );
			};
			
		$pm->finish;
		}
