use Proc::ProcessTable;

$t = new Proc::ProcessTable;

foreach $p (@{$t->table}) 
	{
	next unless $p->{uid} == $< && $p->{ppid} == 1;
	
	printf "%6d %6d %s\n", map { $p->{$_} } qw( pid ppid cmndline );
	
	kill 9, $p->{pid} unless $p->{cmndline} =~ /launch|ssh|webdav|Spotlight/;
	}
