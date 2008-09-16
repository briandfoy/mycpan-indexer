#!/usr/local/bin/perl
use strict;
use warnings;

use YAML qw(LoadFile);

chdir( "/Users/brian/Desktop/report/indexed" );

my %Seen;

opendir DH, "." or die "Could not open dir: $!";

my $bin_size = 100;

my $count = 0;
foreach my $file ( readdir( DH ) )
	{
	next unless $file =~ m/\.yml$/;
	print STDERR "."  unless ++$count %   $bin_size;
	print STDERR "\n" unless   $count % ( $bin_size * 70 );
	
	my $yaml = LoadFile( $file );
	
	my $test_files = $yaml->{dist_info}{test_info};
	
	foreach my $test_file ( @$test_files )
		{
		my $uses = $test_file->{uses};
		
		foreach my $used_module ( @$uses )
			{
			$Seen{$used_module}++;
			}
		}
	}

print "Total module use\n";
foreach my $module ( sort { $Seen{$b} <=> $Seen{$a} } keys %Seen )
	{
	print "$module: $Seen{$module}\n";
	
	last if $Seen{$module} < 100;
	}
