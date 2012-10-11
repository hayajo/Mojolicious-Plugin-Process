use Mojo::Base qw{ -strict };

use Mojo::IOLoop;
use Mojo::URL;
use File::Basename;
use File::Spec;

my $_servers = {};

sub get_server { $_servers->{$_[0]} }

sub start_server {
    my $app   = shift;
    my $port  = shift || Mojo::IOLoop->generate_port;
    # my $pid   = open my $server, '-|', 'morbo', '-l', "http://127.0.0.1:$port", $app
    my $pid   = open my $server, '-|', $^X, $app, 'daemon', '-l', "http://127.0.0.1:$port"
        // die "open failed: $!";
    sleep 3;
    sleep 1
        while !IO::Socket::INET->new(
            Proto    => 'tcp',
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
        );
    my $url = Mojo::URL->new("htt://127.0.0.1:$port");
    $_servers->{$pid} = { handle => $server, url => $url };
    return ($pid, $url);
}

sub stop_server {
    my $pid = shift;
    my $server = $_servers->{$pid};
    die "stop failed: $pid" unless ( $server && kill 0, $pid );
    kill 'INT', $pid;
    sleep 1 while IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1',
        PeerPort => $server->{port},
    );
    delete $_servers->{$pid};
}
