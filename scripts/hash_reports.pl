#!perl

use 5.010;

use File::Path qw(make_path);
use File::Spec::Functions;

my $base = '/Volumes/Atlas/indexer_reports/error';
opendir my $dh, $base;

while( my $file = readdir $dh )
	{
	next if $file =~ /^\./;
	my $full_path = catfile( $base, $file );
	next if -d $full_path;
	my( $first, $second ) = map { uc } map { substr $file, 0, $_ } 1 .. 2;
	
	my $dir  = catfile( $base, $first, $second );
	make_path( $dir ) unless -e $dir;
	my $path = catfile( $dir, $file );
   	
	rename $full_path => $path or die "$!";
	}
