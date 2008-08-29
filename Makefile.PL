# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'MyCPAN::Indexer',
	'ABSTRACT'     => 'Index a Perl distribution',
	'VERSION_FROM' => 'lib/Indexer.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Archive::Extract'                 => '0',
		'Distribution::Guess::BuildSystem' => '0',
		'File::Find::Closures'             => '0',
		'Log::Log4perl'                    => '0',
		'MD5'                              => '0',
		'Module::Extract::Namespaces'      => '0',
		'Module::Extract::Use'             => '0',
		'Module::Extract::VERSION'         => '0',		
		'Probe::Perl'                      => '0',
		'Test::More'                       => '0',
		'Test::Output'                     => '0',
		'YAML::Syck'                       => '0',
		},

	'PM'           => {
		'lib/Indexer.pm' => '$(INST_LIBDIR)/Indexer.pm',
		},

	'MAN3PODS'     => {
		'lib/Indexer.pm' => '$(INST_MAN3DIR)/MyCPAN::Indexer.3',
		},

	clean  => { FILES    => q|MyCPAN-Indexer-*| },

	);
