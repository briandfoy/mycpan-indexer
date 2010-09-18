use Proc::ProcessTable;

$t = new Proc::ProcessTable;

foreach $p (@{$t->table}) 
	{
	next unless $p->{cmndline} =~ /META_new/;
	
	printf "%6d %6d %s\n", map { $p->{$_} } qw( pid ppid cmndline );
	
	kill 9, $p->{pid} if $p->{ppid} == 1;
	}
