use strict;
use warnings;

use Test::More tests => 5;

use Log::Log4perl qw(:easy);

my $class = 'MyCPAN::App::DPAN';
use_ok( $class );

can_ok( $class, 'get_config' );

my $config = $class->get_config;
isa_ok( $config, $class->config_class );

is( $config->indexer_class, 'MyCPAN::Indexer::DPAN' );

can_ok( $class, 'run' );

