#!perl
use utf8;
use 5.013;
use strict;
use warnings;

use Data::Dumper;
use File::Copy;

use File::Basename;
use File::Find;
use File::Find::Closures;
use File::Copy;
use File::Path            qw( make_path );
use File::Spec::Functions qw( catfile );
use YAML::XS              qw( Load );

my @dirs = @ARGV || '/Users/brian/Desktop/sorted_errors';
my $count;
my %error_hash;
my %date_hash;

my $dist_dir = '/Users/brian/Desktop/bad_dists';
make_path( $dist_dir ) unless -d $dist_dir;
die "Did not make $dist_dir\n" unless -d $dist_dir;

my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.yml\z/ );
find( $wanted, @dirs );

FILE: foreach my $file ( $reporter->() ) {
	$count++;
	my $contents = do { local $/; open my $fh, '<:utf8', $file; <$fh> };
	my $yaml = eval { Load( $contents ) };
	unless( defined $yaml ) {
		warn "$file did not parse correctly\n";
		next FILE;
		}

	my $dist_file = $yaml->{dist_info}{dist_file};
	my $short_path = $file =~ s/\Q$dirs[0]\///r;
	my( $new_dir ) = dirname $short_path;
	
	my $sub_dir = catfile( $dist_dir, $new_dir );
	make_path( $sub_dir ) unless -d $sub_dir;
	copy( 
		$dist_file,
		catfile( $sub_dir, basename( $dist_file ) )
		);

	say "$file -> $short_path -> $dist_file";
	
#	last if $count++ > 50;
	}
