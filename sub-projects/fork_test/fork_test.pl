use Parallel::ForkManager;

my $pm = Parallel::ForkManager->new( $ARGV[0] );

my $count = 0;

mkdir "/Users/brian/Desktop/fork_test", 0755
	unless -d "/Users/brian/Desktop/fork_test";

sub Parallel::ForkManager::finish { my ($s, $x) = @_;
  if ( $s->{in_child} ) {
	CORE::exit ($x || 0);
  }
  if ($s->{max_proc} == 0) { # max_proc == 0
	$s->on_finish($$, $x ,$s->{processes}->{$$}, 0, 0);
	delete $s->{processes}->{$$};
  }
  return 0;
}

foreach ( 0 .. $ARGV[1] ) 
	{
	$count++;
    my $pid = $pm->start and next; 

    `$^X -le 0`;
    
    open my($fh), '>', "/Users/brian/Desktop/fork_test/$$.txt"
    	or die "Could not open $$.txt\n";
    print $fh $$;
    
	print $count, '/', $$, "\n";
	
    $pm->finish;
	}
