package MyCPAN::Indexer::Tutorial;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.17_08';

=head1 NAME

MyCPAN::Indexer::Tutorial - How the backpan_indexer.pl pieces fit together

=head1 DESCRIPTION

The MyCPAN::Indexer system lets you plug in different engines to
control major portions of the process. It's up to each class to
obey the interface and do that parts the other portions it expects
it to do. The idea is to decouple some of these bits as much as
possible.

As C<backpan_indexer.pl> does its work, it stores information about
its components in an anonymous hash called C<$Notes>. The different
components have access to this hash. (To Do: this is some pretty bad
design smell, but that's how it is right now).

Specific implementations will impose other requirements not listed
in this tutorial.

=head1 The Queue class

The Queue class is responsible for getting the list of distributions to
process.

C<backpan_indexer.pl> calls C<get_queue> and passes it a ConfigReader::Simple
object. C<get_queue> does whatever it needs to do, then returns an array
reference of file paths to process. Each path should represent a single
Perl distribution.

Implements:

	get_queue( $Notes )

Creates in C<$Notes>:

	queue - a reference to the array reference returned by get_queue.

Expects in C<$Notes>:

	config - the configuration object

To Do: The Queue class should really be an iterator of some sort. Instead
of returning an array (which it can't change), return an iterator.

=head1 The Worker class

The Worker class returns the anonymous subroutine that the interface
class calls for each of its cycles. Inside that code reference, do the
actual indexing work, including saving the results.
C<backpan_indexer.pl> calls C<get_task> with a reference to its
C<$Notes> hash.

Implements:

	get_task( $Notes )

Creates in C<$Notes>

	child_task - a reference to the code reference returned by get_task.

Expects in C<$Notes>

	config - the configuration object

To Do: There should be a storage class which the worker class hands
the results to.

=head1 The Reporter class

The Reporter class implements the bits to store the result of the
Worker class. C<backpan_indexer.pl> calls C<get_storer> with a reference to its
C<$Notes> hash.

Implements:

	get_reporter( $Notes, $info )

Creates in C<$Notes>:

	reporter - the code ref to handle storing the information

Expects in C<$Notes>:

	config

Expects in config:


=head1 The Dispatcher class

The Dispatcher class implements the bits to hand out work to the
worker class. The Interface class, discussed next, repeatedly calls
the interface_callback code ref the Dispatcher class provides.

Implements:

	get_dispatcher( $Notes )

Creates in C<$Notes>

	dispatcher - the dispatcher object, with start and finish methods
	interface_callback - a code ref to call repeatedly in the Interface class

Expects in C<$Notes>

	config     - the configuration object
	child_task - the code ref that handles indexing a single dist
	queue      - the array ref of dist paths

=head1 The Interface class

The Interface class really has two jobs. It makes the live reporting
interface  while C<backpan_indexer.pl> runs, at it repeatedly calls
the dispatcher to start new work.

Implements:

	do_interface( $Notes )

Creates in C<$Notes>

Expects in C<$Notes>

	config             - the configuration object
	interface_callback - a code ref to call repeatedly in the Interface class

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
