#!perl
use utf8;
use 5.010;
use strict;
use warnings;

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );
use YAML                  qw( LoadFile );

my @dirs = @ARGV;
my $count;

my $output_dir = 'extra_reports';

mkdir $output_dir, 0755 unless -d $output_dir;

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

		if( $yaml->{run_info}{indexer_id} =~ /joe\@example\.com/ )
			{
			$yaml->{run_info}{indexer_id} = 'brian d foy <brian.d.foy@gmail.com>';
			}

		my $dist_file = $yaml->{dist_info}{dist_file};
		unless( defined $yaml->{dist_info}{dist_file} )
			{
			warn "$file did have a dist_file entry\n";
			next FILE;
			}
			
		$dist_file =~ s/.*authors.id.//;
		my $basename = basename( $dist_file );
		my $stripped = $basename =~ s/\.(tar\.gz|tgz|zip)\z//;
		unless( $stripped )
			{
			warn "[$basename] still has a file extension\n";
			}
			
		open my $fh, '>', catfile( $output_dir, $basename )
			or do { 
				warn "Could not open extra reports file for [$dist_file]: $!\n";
				next FILE;
				};

		print $fh <<"HEADER";
# This is an extract of the packages and versions found in a Perl distribution.
# You can use collections of these files with MyCPAN::App::DPAN so you don't
# have to analyze files yourself when you want to create a new version of 
# your custom CPAN.
# 
# This extra report was extracted from
# 
# 	run: $yaml->{run_info}{uuid}
# 	date: @{ [ scalar localtime $yaml->{run_info}{run_start_time} ] } ($yaml->{run_info}{run_start_time})
# 	system: $yaml->{run_info}{system_id}
# 	runner: $yaml->{run_info}{indexer_id}
# 
# PACKAGE [TAB] VERSION [TAB] RELATIVE DISTRO FILE
HEADER

		foreach my $module ( @{ $yaml->{dist_info}{module_info} } )
			{
			no warnings 'uninitialized';
				
			my $version = $module->{version_info}{value};
			if( $version =~ /[^0-9_.]/ )
				{
				my $hex = unpack 'H*', $version;
				warn "Strange version in $file for $module->{primary_package}: [$version|$hex]\n";
				}

			write_line( $fh,
				{
				version     => $version || '',
				distro      => $dist_file,
				'package'   => $module->{primary_package},
				}
				);
			}

		}

	}

sub write_line
	{
	my( $fh, $hash ) = @_;

	no warnings 'uninitialized';
	
	say $fh join "\t",
		@{ $hash }{ qw(package version distro) };	
	}
