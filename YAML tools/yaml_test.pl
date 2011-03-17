#!perl
use utf8;
use 5.010;
use strict;
use warnings;

no warnings 'uninitialized';

use File::Spec::Functions qw( catfile );
use YAML::Syck qw();  # Load
use YAML qw();        # LoadFile
use YAML::XS qw();    # Load
use YAML::Tiny qw();  # YAML::Tiny−>read( 'file.yml' )

my @dirs = @ARGV;
my $count;

my %readers = (
	'YAML'       => sub { YAML::LoadFile( $_[0] ) },
	'YAML::XS'   => sub { YAML::XS::LoadFile( $_[0] ) },
	'YAML::Syck' => sub { YAML::Syck::Load( $_[0] ) },
	'YAML::Tiny' => sub { YAML::Tiny->read( $_[0] ) },
	);
my @readers = qw( YAML::XS YAML::Syck YAML::Tiny );

my $files = 0;
my %failures;

DIR: while( my $dir = shift @dirs ) {
	opendir my $dh, $dir or die "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) ) {
		next if $file =~ /^\./;
		my $path = catfile( $dir, $file );
		print STDERR "path does not exist: $path\n" unless -e $path;
		if( -d $path ) {
			push @dirs, $path;
			next FILE;
			}
		
		$files++;

		READER: foreach my $reader ( @readers ) {
			my $yaml = eval { $readers{$reader}->( $path ) };
			my $at = $@;
			next FILE unless $at;
			push @{ $failures{$path} }, $reader;
			}
		}
	
	close $dh;
	}

foreach my $failure ( sort keys %failures ) {
	print "$failure\t@{ $failures{$failure} }\n";
	}

printf "There are %d failures in %d files\n", scalar keys %failures, $files;
