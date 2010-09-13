#!perl

use 5.010;

use File::Spec::Functions;

my( $index_dir ) = @ARGV;

opendir my $dh, catfile( $index_dir, 'success' ) 
	or die "Could not open $index_dir: $!";

$hits = 0;
while( my $file = readdir $dh )
	{
	next if /\A\./;
	$files++;
	my $error_file = catfile( $index_dir, 'error', $file );
	print "error_file is $error_file\n";
	$hits++ if -e $error_file;
	}
	
print "files are $files\nhits are $hits\n";
