package MyCPAN::Indexer::Interface::Text;
use strict;
use warnings;

use Log::Log4perl qw(:easy);
use Curses;

use vars qw($VERSION);
$VERSION = '1.16_01';

=head1 NAME

MyCPAN::Indexer::Interface::Test - Present the run info as a text

=head1 SYNOPSIS

Use this in backpan_indexer.pl by specifying it as the interface class:

	# in backpan_indexer.config
	interface_class  MyCPAN::Indexer::Interface::Text

=head1 DESCRIPTION

This class presents the information as the indexer runs, using plain text.

=head2 Methods

=over 4

=item do_interface( $Notes )


=cut

BEGIN { $SIG{INT} = sub { exit } }

sub do_interface 
	{
	my( $class, $Notes ) = @_;
	DEBUG "Calling do_interface";
	
	print "BackPAN Indexer 1.00\n";	

	print 'Processing ' . @{ $Notes->{queue} } . " distributions\n";
	print "One * = 1 distribution\n";
	
	my $count = 0;
	while( 1 )
		{
		last if $Notes->{Left} <= 0;
	
		print "This is in do_interface\n";
		local $|;
		$|++;
		
		print "*";
		print "\n" unless ++$count % 70;
		
		$Notes->{interface_callback}->();
		}

	print "\n";
	
	}


=back


=head1 SEE ALSO

MyCPAN::Indexer

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;