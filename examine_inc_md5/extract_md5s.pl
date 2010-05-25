#!perl
use utf8;
use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use YAML qw( LoadFile );

my @dirs = @ARGV;
my $count;

foreach my $dir ( @dirs )
	{
	opendir my $dh, $dir or warn "Could not open $dir: $!\n";
	
	FILE: while( my $file = readdir( $dh ) )
		{
		next if $file =~ /^\./;
		
		my $yaml = eval { LoadFile( catfile( $dir, $file ) ) };
		unless( defined $yaml )
			{
			warn "$file did not parse correctly\n";
			next FILE;
			}

		my $dist_file = $yaml->{dist_info}{dist_file};
		unless( defined $yaml->{dist_info}{dist_file} )
			{
			warn "$file did have a dist_file entry\n";
			next FILE;
			}
			
		$dist_file =~ s/.*authors.id.//;
		
		foreach my $module ( @{ $yaml->{dist_info}{module_info} } )
			{
			no warnings 'uninitialized';
				
			my $version = $module->{version_info}{value};
			if( $version =~ /[^0-9_.]/ )
				{
				my $hex = unpack 'H*', $version;
				warn "Strange version in $file for $module->{primary_package}: [$version|$hex]\n";
				}

			write_line(
				{
				version   => $version || '',
				blib      => 1,
				dist_file => $dist_file,
				map {; $_ => $module->{$_} } qw(md5 name bytesize primary_package)
				}
				);
			}

		foreach my $file ( @{ $yaml->{dist_info}{manifest_file_info} } )
			{
			no warnings 'uninitialized';
			next if $file->{name} =~ m<(^|/)\.(git|svn)/>;
			
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

sub write_line
	{
	my( $hash ) = shift;
	no warnings 'uninitialized';
	
	say join "|",
		@{ $hash }{ qw(md5 name blib bytesize primary_package version dist_file) };	
	}
