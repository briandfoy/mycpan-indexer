#!perl
use utf8;
use 5.014;
use strict;
use warnings;

use Data::Dumper;
use File::Copy;

use File::Basename;
use File::Copy;
use File::Path            qw( make_path );
use File::Spec::Functions qw( catfile );
use YAML::XS              qw( Load );

my @dirs = @ARGV || '/Volumes/Atlas/indexer_reports/error';
my $count;
my %error_hash;
my %date_hash;

my $sort_dir = '/Users/brian/Desktop/sorted_errors';
make_path( $sort_dir ) unless -d $sort_dir;

my $error = sub {
	my( $file, $key, $yaml ) = @_;
	my $basename = basename( $file );
	
	$error_hash{$key}++;

	my $copy_to = catfile( $sort_dir, $key, $basename ); 
	say "[$key] $file -> $copy_to";
	my $dir = dirname( $copy_to );
	make_path( $dir ) unless -d $dir;
	
	copy(
		$file,
		$copy_to, 
		) unless -e $copy_to;
	
	return unless defined $yaml;
	
	my $epoch = $yaml->{dist_info}{dist_date};
	my( $year, $month ) = ( localtime $epoch )[5,4];
	
	$date_hash{$year+1900}++;
	};

die "Did not make $sort_dir\n" unless -d $sort_dir;

foreach my $dir ( @dirs )
	{
	print "Processing $dir\n";
	
	FILE: while( my $file = glob( catfile( $dir, '*', '*', '*.yml' ) ) )
		{
		$count++;
		my $contents = do { local $/; open my $fh, '<:encoding(UTF-8)', $file; <$fh> };
		my $yaml = eval { Load( $contents ) };
		unless( defined $yaml )
			{
			#warn "$file did not parse correctly\n";
			$error->( $file, 'unparseable', undef );
			next FILE;
			}

		my $dist_file = $yaml->{dist_info}{dist_file};
		unless( defined $yaml->{dist_info}{dist_file} )
			{
			#warn "$file did have a dist_file entry\n";
			$error->( $file, 'no dist', $yaml );
			next FILE;
			}
			
		$dist_file =~ s/.*authors.id.//;
		
		my $classification;
		KEY: foreach my $key ( keys %{ $yaml->{run_info} } )
			{
			next unless $key =~ /(^|_)error\z/;
			
			# say join " ", $key, $yaml->{run_info}{$key}, $dist_file;

			$classification = do { 
				given( $yaml->{run_info}{$key} ) {
					when( /alarm rang/i )    { 'alarm' }
					when( /unpack dist/i )   { 'unpack' }
					when( /file list/i )     { 'file list' }
					when( /find modules/i )     { 'module list' }
					when( /find distro/i )   { 'find distro' }
					when( /run build/i )     { 'run build' }
					when( /META\.yml/i )     { 'metayml' }
					when( /YAML/i )          { 'yaml' }
					when( /dist size was 0/i )          { '0 dist size' }
					when( /permission denied/i )          { 'permission denied' }
					default                  { 0 }
					}
				};

			last KEY if $classification;
			}
		
		unless( $classification ) {
			$classification = do {
				given( $yaml->{dist_info}{build_target_distdir_output} ) {
					when( /perl script "distdir"/i )    { 'distdir' }
                    when( /make target `distdir'/i )    { 'distdir' }
					}
				};
			}
				
		$error->( $file, $classification || 'unclassified', $yaml );

		
		# last if $count++ > 50;
		}

	}

print Dumper( $count, \%error_hash, \%date_hash );
