use Mojo::Base qw{ -strict };
use File::Basename;
use File::Spec;

my $dir = dirname(__FILE__);
require File::Spec->catfile( $dir, 'util.pl' );

use Test::More tests => 3;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Capture::Tiny qw{ tee_stderr };

my $app = File::Spec->catfile( $dir, 'app', 'app.pl' );

local $SIG{ALRM} = sub {
    BAIL_OUT("test failed. probably the problem happend in capture_stderr.");
};
alarm 10;

my $tx;
my $stderr = tee_stderr {
    my ($server_pid, $url) = start_server($app);
    my $ua = Mojo::UserAgent->new;
    $tx = $ua->get( $url->path('/stdin')->to_string );
    sleep 4;
    stop_server($server_pid);
};

ok $tx->is_finished;
is $tx->res->code, 200;

my $pid = $tx->res->body;
like $stderr, qr/$pid foobarbuz/m;

done_testing;
