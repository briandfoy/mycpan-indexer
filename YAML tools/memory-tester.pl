#!perl
use utf8;
use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use YAML::XS qw(  );

my @dirs = @ARGV;
my $count;
$|++;

print STDERR "Pid is $$\n";

DIR: while( my $dir = shift @dirs ) {
	opendir my $dh, $dir or warn "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) ) {
		next if $file =~ /^\./;
		next if $file =~ /\.yamlpm/;
		my $path = catfile( $dir, $file );
		if( -d $path ) {
			warn "Putting $path into queue\n";
			push @dirs, $path;
			next FILE;
			}
		
		my $yaml = eval { YAML::XS::LoadFile( $path ) };
		my $at = $@;

		unless( ref $yaml ) {
			warn "$path did not parse correctly $@\n";
			next FILE;
			}
			
		my $dist_file = $yaml->{dist_info}{dist_file};
		print "Dist file is $dist_file\n";
		}
		
	closedir $dh;
	}

warn "Done processing, cleaning up...\n";
exit;

