package MyCPAN::Indexer::Interface::Text;
use strict;
use warnings;

use Log::Log4perl;

use vars qw($VERSION $logger);
$VERSION = '1.18_03';

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

BEGIN {
	$logger = Log::Log4perl->get_logger( 'Interface' );
	}

sub do_interface
	{
	my( $class, $Notes ) = @_;
	$logger->debug( "Calling do_interface" );

	print "BackPAN Indexer 1.00\n";

	print 'Processing ' . @{ $Notes->{queue} } . " distributions\n";
	print "One * = 1 distribution\n";

	my $count = 0;
	while( 1 )
		{
		last if $Notes->{Finished};

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
