use Mojolicious::Lite;
use Mojo::Util;

plugin 'Process';

get '/' => sub {
    my $self   = shift;
    my $stream = $self->process(
        'perl',
        cmd_args => [ '-e', 'sleep' ],
        timeout  => 0,
    );
    $self->render( text => $stream->pid );
};

get '/handler' => sub {
    my $self   = shift;
    my $stream = $self->process(
        'perl',
        cmd_args => [ '-e', 'local $| = 1; sleep 3; print "Hello"' ],
        handler => {
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
        'perl',
        cmd_args => [ '-e', 'local $| = 1; sleep 10; print "Hello"' ],
        handler => {
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

app->start;
