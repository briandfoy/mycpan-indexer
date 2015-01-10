use v5.14.2;
use strict;
use warnings;

my %optional = (
	Curses  => {
		'lib/MyCPAN/Indexer/Interface/Curses.pm' => '$(INST_LIBDIR)/Indexer/Interface/Curses.pm',
	
		},
	Tk      => {
		'lib/MyCPAN/Indexer/Interface/Tk.pm' => '$(INST_LIBDIR)/Indexer/Interface/Tk.pm',
		},
	);

foreach my $module ( keys %optional ) {
	my $available = eval "require $module; 1";
	
	unless( $available ) {
		print <<"HERE";
$module not available. Skipping optional modules that use it.
If you later want to use it, you'll have to reinstall MyCPAN.
HERE

		delete $optional{ $module };
		}
	}
	
use File::Spec::Functions qw(catfile);

my $module    = 'MyCPAN::Indexer';
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/briandfoy/mycpan-indexer';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'NAME'	        => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More'   => '0.94',
		'Test::Output' => '0.13',
		},

	'PREREQ_PM'    => {
		'Archive::Zip'                     => '0',
		'Archive::Extract::Libarchive'     => '0',
		'ConfigReader::Simple'             => '0',
		'CPAN::Checksums'                  => '0',
		'CPAN::PackageDetails'             => '0.21',
		'Data::Structure::Util'            => '0',
		'Data::UUID'                       => '0',
		'Digest::MD5'                      => '0',
		'Distribution::Guess::BuildSystem' => '0.11',
		'ExtUtils::MakeMaker'              => '6.48',
		'File::Find::Closures'             => '0',
		'File::Find'                       => '0',
		'File::Which'                      => '0',
		'List::Util'                       => '0',
		'Log::Log4perl'                    => '0',
		'Module::Extract::Namespaces'      => '0.14',
		'Module::Extract::Use'             => '0.13',
		'Module::Extract::VERSION'         => '0.13',
		'Parallel::ForkManager'            => '0',
		'Probe::Perl'                      => '0',
		'Proc::ProcessTable'               => '0',
		'YAML::Syck'                       => '0',
		'YAML::XS'                         => '0',
		'YAML'                             => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtraker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		no_index => {
			directory => [ qw(t inc corpus test-corpus) ],
			},
		},

	clean => { FILES => "$dist-*" },
	);

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			//
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21" 
		if -e File::Spec->catfile( qw(t test_manifest) );
	WriteMakefile( %WriteMakefile );
	}


no warnings;
__PACKAGE__;
