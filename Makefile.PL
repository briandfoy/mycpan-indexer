# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'MyCPAN::Indexer',
	'ABSTRACT'     => 'Index a Perl distribution',
	'VERSION_FROM' => 'lib/Indexer.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Archive::Extract'                 => '0',
		'Distribution::Guess::BuildSystem' => '0',
		'File::Find'                       => '0',
		'File::Find::Closures'             => '0',
		'Log::Log4perl'                    => '0',
		'MD5'                              => '0',
		'Module::Extract::Namespaces'      => '0',
		'Module::Extract::Use'             => '0',
		'Module::Extract::VERSION'         => '0',
		'Parallel::ForkManager'            => '0',
		'Probe::Perl'                      => '0',
		'Test::More'                       => '0',
		'Test::Output'                     => '0',
		'Tk'                               => '0',
		'Tk::ProgressBar'                  => '0',
		'YAML::Syck'                       => '0',
		'YAML'                             => '0',
		},

	'PM'           => {
		'lib/Indexer.pm'  => '$(INST_LIBDIR)/Indexer.pm',
		'lib/Parallel.pm' => '$(INST_LIBDIR)/Indexer/Dispatch/Parallel.pm',
		'lib/Tk.pm'       => '$(INST_LIBDIR)/Indexer/Interface/Tk.pm',
		'lib/Queue.pm'    => '$(INST_LIBDIR)/Indexer/Queue.pm',
		'lib/Worker.pm'   => '$(INST_LIBDIR)/Indexer/Worker.pm',
		'lib/Tutorial.pm' => '$(INST_LIBDIR)/Indexer/Tutorial.pm',
		},

	'MAN3PODS'     => {
		'lib/Indexer.pm'  => '$(INST_MAN3DIR)/MyCPAN::Indexer.3',
		'lib/Parallel.pm' => '$(INST_MAN3DIR)/MyCPAN::Indexer::Dispatch::Parallel.3',
		'lib/Tk.pm'       => '$(INST_MAN3DIR)/MyCPAN::Indexer::Interface::Tk.3',
		'lib/Queue.pm'    => '$(INST_MAN3DIR)/MyCPAN::Indexer::Queue.3',
		'lib/Worker.pm'   => '$(INST_MAN3DIR)/MyCPAN::Indexer::Worker.3',
		'lib/Tutorial.pm' => '$(INST_MAN3DIR)/MyCPAN::Indexer::Tutorial.3',
		},

	clean  => { FILES    => q|MyCPAN-Indexer-*| },

	);
