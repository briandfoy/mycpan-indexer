#!perl
use utf8;
use 5.010;
use strict;
use warnings;

use Benchmark;
use File::Map qw( map_file );
use File::Spec::Functions qw( catfile );
use YAML::XS qw(  );

my @dirs = @ARGV;
my @files = ();
DIR: while( my $dir = shift @dirs ) {
	opendir my $dh, $dir or warn "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) ) {
		next if $file =~ /^\./;
		next if $file =~ /\.yamlpm/;
		my $path = catfile( $dir, $file );
		if( -d $path ) {
			push @dirs, $path;
			next FILE;
			}
		push @files, catfile( $dir, $file );
		}
	}
say "There are " . @files . " files";

{
my $start = Benchmark->new;
foreach my $file ( @files ) {
	my $yaml = eval { YAML::XS::LoadFile( $file ) };
	}
my $end = Benchmark->new;
my $diff = timediff( $end, $start );
warn sprintf "LoadFile in %s\n", timestr( $diff );
}

{
my $start = Benchmark->new;
foreach my $file ( @files ) {
		my $yaml = eval { map_file my($y), $file; YAML::XS::Load( $y ) };
	}
my $end = Benchmark->new;
my $diff = timediff( $end, $start );
warn sprintf "Map in %s\n", timestr( $diff );
}
