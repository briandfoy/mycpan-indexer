use utf8;
use strict;
use warnings;

use vars qw( @classes );

BEGIN {
	use File::Find;
	use File::Find::Closures;
	use File::Spec;
	
	my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.pm\z/ );
	find( $wanted, File::Spec->catfile( qw(blib lib) ) );

	@classes = map {
		s/\.pm\z//;
		
		my @parts = File::Spec->splitdir( $_ );
		splice @parts, 0, 2, ();
		join "::", @parts;
		} $reporter->();
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}
