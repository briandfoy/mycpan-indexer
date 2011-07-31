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

open my( $fh ), '>:encoding(UTF-8)', 'backpan_md5_internal.txt';

DIR: while( my $dir = shift @dirs ) {
	warn "Processing $dir: " . @dirs . " left\n";
	opendir my $dh, $dir or warn "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) ) {
		warn "Processing $file\n";
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
		unless( defined $yaml->{dist_info}{dist_file} ) {
			warn "$file did have a dist_file entry\n";
			next FILE;
			}
			
		$dist_file =~ s/.*authors.id.//;

		foreach my $module ( @{ $yaml->{dist_info}{module_info} } ) {
			no warnings 'uninitialized';

			write_line(
				{
				version   => handle_version( $module->{version_info}{value} ),
				blib      => 1,
				dist_file => $dist_file,
				map {; $_ => $module->{$_} } qw(md5 name bytesize primary_package)
				}
				);
			}

		foreach my $file ( @{ $yaml->{dist_info}{manifest_file_info} } ) {
			no warnings 'uninitialized';
			next if $file->{name} =~ m<(\A|/)\.(git|svn|CVS)/>;
			next unless $file->{name} =~ m<\.p[ml]\z>;
			
			write_line(
				{
				version         => '',
				blib            => 0,
				dist_file       => $dist_file,
				primary_package => '',
				map {; $_ => $file->{$_} } qw(name md5 bytesize)
				}
				);
			}

		}

	}

warn "Done processing, cleaning up...\n";
exit;

sub handle_version {
	my( $version ) = @_;
	return '' unless defined $version;

	$version =~ s/^\s*|\s+$//g;

	if( $version =~ m/[\000-\037]/ ) {
		warn "Found stupid v version... now is ";
		my $hex = unpack 'H*', $version;
		$version = 'v' . join '.', map { $_ + 0 } $hex =~ m/(..)/g;
		warn "$version\n";
		}

	if( $version =~ /[^0-9a-z_.-]/i ) {
		warn "Strange version [$version]\n";
		}

	$version || '';
	}

sub write_line
	{
	my( $hash ) = shift;
	no warnings 'uninitialized';
	
	say { $fh } join "|",
		@{ $hash }{ qw(md5 name blib bytesize primary_package version dist_file) };	
	}
