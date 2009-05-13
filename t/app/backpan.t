use strict;
use warnings;

use Test::More tests => 5;

use Log::Log4perl qw(:easy);

my $class = 'MyCPAN::App::BackPAN::Indexer';
use_ok( $class );

can_ok( $class, 'get_config' );

my $config = $class->get_config;
isa_ok( $config, $class->config_class );

is( $config->indexer_class, 'MyCPAN::Indexer' );

can_ok( $class, 'activate' );
