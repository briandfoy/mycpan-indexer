#!perl
use warnings;
use strict;

use File::Spec::Functions;

my( $dir ) = @ARGV;

opendir my($dh), $dir or die "Could not open $dir! $!\n";

while( my $file = readdir( $dh ) )
	{
	next if $file =~ /^\./;
	local @ARGV = catfile( $dir, $file );
	my @errors;

	while( <> )
		{
		next unless defined $_;
		next if /error_report_subdir/;
		#push @errors, "$file: $_" if /\berror(?!_)/;
		print  "$file: $_" if /\berror(?!_)/;
		}
	}
