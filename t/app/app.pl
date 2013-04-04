use Mojolicious::Lite;
use Mojo::Util;

plugin 'Process';

get '/' => sub {
    my $self   = shift;
    my $stream = $self->process(
        command => [qw/perl -e sleep/],
    );
    $self->render( text => $stream->pid );
};

get '/handler' => sub {
    my $self   = shift;
    my $stream = $self->process(
        command => [ qw/perl -e/, 'local $| = 1; sleep 3; print "Hello"' ],
        stdout  => {
            read => sub {
                my ($stream, $chunk) = @_;
                my $pid = $stream->pid;
                app->log->warn("$pid $chunk");
            }
        },
    );
    $self->render( text => $stream->pid );
};

get '/timeout' => sub {
    my $self   = shift;
    my $stream = $self->process(
        command => [ 'perl', '-e', 'local $| = 1; sleep 10; print "Hello"' ],
        stdout  => {
            read => sub {
                my ($stream, $chunk) = @_;
                my $pid = $stream->pid;
                app->log->warn("$pid $chunk");
            },
            timeout => sub {
                my $pid = $_[0]->pid;
                app->log->warn("$pid timeout");
            },
            close => sub {
                my $pid = $_[0]->pid;
                app->log->warn("$pid close");
            },
        },
        timeout => 3,
    );
    $self->render( text => $stream->pid );
};

get '/stderr' => sub {
    my $self   = shift;
    my $stream = $self->process(
        command => [ qw/perl -e/, 'local $| = 1; sleep 3; print "Hello STDOUT"; print STDERR "Hello STDERR"' ],
        stdout  => {
            read => sub {
                my ($stream, $chunk) = @_;
                my $pid = $stream->pid;
                app->log->warn("$pid $chunk");
            }
        },
        stderr => {
            read => sub {
                my ($stream, $chunk) = @_;
                my $pid = $stream->pid;
                app->log->error("$pid $chunk");
            }
        },
    );
    $self->render( text => $stream->pid );
};

get '/stdin' => sub {
    my $self   = shift;
    my ($stream, $stdin) = $self->process(
        command => [ qw/perl -e/, 'print <STDIN>' ],
        stdout  => {
            read => sub {
                my ($stream, $chunk) = @_;
                my $pid = $stream->pid;
                app->log->warn("$pid $chunk");
            }
        },
    );
    print $stdin "foobarbuz";
    $self->render( text => $stream->pid );
};

app->start;
