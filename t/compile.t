# $Id: load.t,v 1.2 2004/09/08 00:25:42 comdog Exp $
use File::Spec::Functions qw(catfile);
use Test::Output;

BEGIN {
	@scripts = map { catfile( 'examples', $_ ) } qw( backpan_indexer.pl );
	}

use Test::More tests => 2 * scalar @scripts;

foreach my $script ( @scripts )
	{
	ok( -e $script, "$script exists" );
	
	my $output = `$^X -c $script 2>&1`;
	
	print "Bail out! $script did not compile\n"
		unless like( $output, qr/syntax ok/i, "Script $script compiles" );
	}
