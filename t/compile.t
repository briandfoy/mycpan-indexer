use Test::More;

use File::Spec::Functions qw(catfile);
use Test::Output;

open my($fh), "<", "MANIFEST" or die "Could not open MANIFEST! $!";

my @scripts =
	map  { catfile( split m|/| ) }
	grep { /\.pl$/ }
	map  { chomp; $_ }
	<$fh>;

foreach my $script ( @scripts ) {
	ok( -e $script, "$script exists" );

	my $output = `$^X -c $script 2>&1`;

	print "Bail out! $script did not compile\n"
		unless like( $output, qr/syntax ok/i, "Script $script compiles" );
	}

done_testing();
