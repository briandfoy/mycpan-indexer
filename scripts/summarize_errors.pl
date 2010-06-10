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
		
		foreach my $key ( keys %{ $yaml->{run_info} } )
			{
			next unless $key =~ /_error\z/;
			say join " ", $key, $yaml->{run_info}{$key}, $dist_file;
			}

		}

	}
