#!perl

use Data::Dumper;
use File::Find;
use File::Find::Closures qw(find_by_regex);
use YAML::XS;
use YAML;

my( $wanted, $reporter ) = 
	File::Find::Closures::find_by_regex( qr/\.yamlpm\z/ );
	
find( $wanted, '/Volumes/Atlas/indexer_reports/success/' );


foreach my $file ( $reporter->() ) {
	print "Processing $file...\n";
	my $yaml = YAML::LoadFile( $file );
	my $dump = YAML::XS::Dump( $yaml );
	warn "\tShort YAML!\n" if length $dump < 100;
	
	( my $yaml_name = $file ) =~ s/\.yamlpm\z//;
	
	open my $out, '>:utf8', $yaml_name;
	
	print {$out} $dump, "\n";
	}
