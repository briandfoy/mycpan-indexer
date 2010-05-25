#!perl
use utf8;
use 5.010;
use strict;
use warnings;


use DBI;
use Digest::MD5;
use File::Find::Closures qw(find_regular_files);
use File::Find;

my $dbfile = $ARGV[0];

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", '', '' );
my $sth = $dbh->prepare( 'SELECT * FROM backpan_md5 WHERE md5 = ?' );

my( $wanted, $reporter ) = File::Find::Closures::find_regular_files();
find( $wanted, @INC );

my $files = $reporter->();
print "Found " . @$files . " files\n";

my( $examined, $misses ) = ( 0, 0 );
FILE: foreach my $file ( @$files )
	{
	next if $file =~ m|/auto/|;
	next if $file =~ m|/darwin-2level/|;
	next if $file =~ m|/.packlist\z|;
	$examined++;
	
	my $md5 = md5_hex_file( $file );
	
	print "$file $md5 -> ";
	
	$sth->execute( $md5 );
	my $results = $sth->fetchall_arrayref;

	if( @$results == 0 )
		{
		$misses++;
		print " no matches\n";
		next FILE;
		}

	print "\n";
	foreach my $result ( @$results )
		{
		print Dumper( $result ), "\n";
		}
	
	}

my $ratio = int( eval { $misses / $examined } * 100 );
print "
Examined: $examined
Misses:   $misses
Ratio:    $ratio
";

sub md5_hex_file
	{
	my( $file ) = shift;
	
	my $ctx = Digest::MD5->new;
	
	open my $fh, '<', $file or return;
	$ctx->addfile( $fh );
	
	lc $ctx->hexdigest;
	}
