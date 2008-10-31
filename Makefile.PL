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
		'Archive::Tar'                     => '0',
		'ConfigReader::Simple'             => '0',
		'Data::UUID'                       => '0',
		'Distribution::Guess::BuildSystem' => '0.11',
		'File::Find'                       => '0',
		'File::Find::Closures'             => '0',
		'Log::Log4perl'                    => '0',
		'MD5'                              => '0',
		'Module::Extract::Namespaces'      => '0.14',
		'Module::Extract::Use'             => '0.13',
		'Module::Extract::VERSION'         => '0',
		'Parallel::ForkManager'            => '0',
		'Probe::Perl'                      => '0',
		'Test::More'                       => '0',
		'Test::Output'                     => '0',
		'YAML::Syck'                       => '0',
		'YAML'                             => '0',
		'CPAN::PackageDetails'             => '0',
		'CPAN::Checksums'                  => '0',
		},

	'PM'           => {
		'lib/AsYAML.pm'      => '$(INST_LIBDIR)/Indexer/Reporter/AsYAML.pm',
		'lib/Text.pm'        => '$(INST_LIBDIR)/Indexer/Interface/Text.pm',
		'lib/Curses.pm'      => '$(INST_LIBDIR)/Indexer/Interface/Curses.pm',
		'lib/Indexer.pm'     => '$(INST_LIBDIR)/Indexer.pm',
		'lib/NullTester.pm'  => '$(INST_LIBDIR)/Indexer/NullTester.pm',
		'lib/Parallel.pm'    => '$(INST_LIBDIR)/Indexer/Dispatch/Parallel.pm',
		'lib/Queue.pm'       => '$(INST_LIBDIR)/Indexer/Queue.pm',
		'lib/TestCensus.pm'  => '$(INST_LIBDIR)/Indexer/TestCensus.pm',
		'lib/DPAN.pm'        => '$(INST_LIBDIR)/Indexer/DPAN.pm',
		'lib/Tk.pm'          => '$(INST_LIBDIR)/Indexer/Interface/Tk.pm',
		'lib/Tutorial.pm'    => '$(INST_LIBDIR)/Indexer/Tutorial.pm',
		'lib/Worker.pm'      => '$(INST_LIBDIR)/Indexer/Worker.pm',
		'lib/App/DPAN.pm'    => '$(INST_LIBDIR)/App/DPAN.pm',
		'lib/App/Indexer.pm' => '$(INST_LIBDIR)/App/BackPAN/Indexer.pm',
		},

	'MAN3PODS'     => {},

	clean  => { FILES    => q|MyCPAN-Indexer-*| },

	);
