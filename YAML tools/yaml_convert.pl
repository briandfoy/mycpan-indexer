#!perl
use utf8;
use 5.010;
use strict;
use warnings;

no warnings 'uninitialized';

use File::Spec::Functions qw( catfile );
use Term::ANSIColor qw(:constants);

use YAML::Syck qw();  # Load
use YAML       qw();  # LoadFile
use YAML::XS   qw();  # Load
use YAML::Tiny qw();  # YAML::Tiny−>read( 'file.yml' )

my @dirs = @ARGV;
my $count;

use constant SUCCESS => 1;

my %readers = (
	'YAML'       => sub { YAML::LoadFile( $_[0] ); 1 },
	'YAML::XS'   => sub { YAML::XS::LoadFile( $_[0] ); 1 },
	'YAML::Syck' => sub { YAML::Syck::Load( $_[0] ); 1 },
	'YAML::Tiny' => sub { YAML::Tiny->read( $_[0] ); 1 },
	);
my @readers = qw( YAML::XS YAML::Syck YAML::Tiny );

my $files         = 0;
my $errors        = 0;
my $unconvertible = 0;

my %bad_lines;

open my($error_fh), '>', '/Users/brian/Desktop/yaml_errors.txt';
{
my $old = select( $error_fh );
$|++;
select( $old );
}

DIR: while( my $dir = shift @dirs ) {
	opendir my $dh, $dir or die "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) ) {
		next if $file =~ /\A\./;
		next if $file =~ /\.yamlpm\z/;
		my $path = catfile( $dir, $file );
		print STDERR "path does not exist: $path\n" unless -e $path;
		if( -d $path ) {
			push @dirs, $path;
			next FILE;
			}
		
		$files++;

		next FILE if eval{ $readers{'YAML::XS'}->($path) } == SUCCESS;
		my $at = $@;
		$errors++;
		
		my( $line_number ) = $at =~ m/,\sline:\s(\d+),/g;

		my $line = get_line_by_number( $path, $line_number );
		print BLUE, "$path [$line]\n", RESET;
		
		$bad_lines{$line}++;
		
		my $converted;
		unless( eval{ $readers{'YAML'}->($path) } == SUCCESS ) {
			print RED, "$path had problems with YAML: $@\n", RESET;
			say $error_fh $path;
			$unconvertible++;
			next FILE;
			}
		
		my $yaml = $readers{'YAML'}->($path);
		my $temp_file = "$path.new";
		open my($fh), '>:utf8', $temp_file;
		eval { print { $fh } YAML::XS::Dump( $yaml ) };
		if( $@ ) {
			print STDERR RED, "Couldn't re-dump [$path]: $@\n", RESET if $@;
			next FILE;
			}
		close $fh;
		
		rename $path => "$path.yamlpm" or warn "Couldn't move [$path] to [$path.yamlpm]: $!\n";
		rename $temp_file => $path     or warn "Couldn't move [$temp_file] to [$path]: $!\n";
		}
	
	close $dh;
	}

foreach my $bad_line ( keys %bad_lines ) {
	printf "%4d: %s\n", $bad_lines{$bad_line}, $bad_line;
	}

printf "Examined %d files, found %d bad ones, with %d really bad ones\n",
	$files, $errors, $unconvertible;

sub get_line_by_number {
	my( $path, $line_number ) = @_;
	
	open my $fh, '<', $path;
	my $line;
	while( $line = <$fh> ) { last if $. == $line_number }
	chomp( $line );
	$line;
	}
