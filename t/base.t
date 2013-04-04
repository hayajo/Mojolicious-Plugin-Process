use Mojo::Base qw{ -strict };
use File::Basename;
use File::Spec;

my $dir = dirname(__FILE__);
require File::Spec->catfile( $dir, 'util.pl' );

use Mojo::IOLoop;
use Mojo::UserAgent;
use Test::More;
use POSIX;

my $app = File::Spec->catfile( $dir, 'app', 'app.pl' );
my ( $server_pid, $url ) = start_server($app);

my $ua = Mojo::UserAgent->new;
my $tx = $ua->get( $url->to_string );

ok $tx->is_finished;
is $tx->res->code, 200;
my $pid = $tx->res->body;
ok $pid;
ok kill(0, $pid);

stop_server($server_pid);

done_testing;
