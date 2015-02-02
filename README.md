# NAME

Mojolicious::Plugin::Process - execute a non-blocking command

# SYNOPSIS

    # Mojolicious
    sub stratup {
        my $self = shift;
        $self->plugin('Process');
        ...;
    }

    # Mojolicious::Lite
    plugin 'Process';

    # in controller
    get '/job' => sub {
        my $c      = shift;
        my $job_id = MyApp->create_id( $c->req->params->to_hash );
        $c->stash( id => $job_id );
        $c->render('accept');

        if ($job_id) {

            # async execution of time-consuming process
            $c->process(
                command => [ 'job-command', 'id', $job_id ],
                stdout  => {
                    close => sub {
                        my ($stream) = @_;
                        app->log->info( sprintf( '[%s] end job', $stream->pid ) );
                    },
                },
                stderr => {
                    read => sub {
                        my ( $stream, $chunk ) = @_;
                        chomp $chunk;
                        app->log->err( sprintf( '[%d] %s', $stream->pid, $chunk ) );
                    },
                },
                timeout => 0,
            );
        }
    };

# DESCRIPTION

Mojolicious::Plugin::Process is a plugin for Mojolicious apps to execute a non-blocking command.

# METHODS

[Mojolicious::Plugin::Process](https://metacpan.org/pod/Mojolicious::Plugin::Process) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin).

# HELPERS

[Mojolicious::Plugin::Process](https://metacpan.org/pod/Mojolicious::Plugin::Process) contains a helper: _process_.

## `process`

    my ( $pid, $stdin ) = $self->process(
        command => [ 'job-command', 'id', $job_id ],
        stdout => {
            read => sub {
                my ( $stream, $chunk ) = @_;
                chomp $chunk;
                app->log->info( sprintf( '[%s] %s', $stream->pid, $chunk ) );
            },
            close => sub {
                my ($stream) = @_;
                app->log->info( sprintf( '[%s] end process', $stream->pid ) );
            },
        },
        timeout => 0,
    );

### ARGUMENTS

`process` supports the following arguments

- command: _ArrayRef_

    command. this is requried argument.

        command => [ 'echo', 'foo' ]

- stdout: _HashRef_, stderr: _HashRef_

    can emit the following [Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo::IOLoop::Stream) events.

    `close`, `error`, `read`, `timeout`

    in handler, `$stream` is a [Mojo::IOLoop::Stream::Process](https://metacpan.org/pod/Mojo::IOLoop::Stream::Process) Ojbect.

    [Mojo::IOLoop::Stream::Process](https://metacpan.org/pod/Mojo::IOLoop::Stream::Process) has the following attributes.

    `ioloop_id`, `pid`, `command`

        stdout => {
            read => sub {
                my ($stream, $chunk) = @_;
                chomp $chunk;
                app->log->info( sprintf('[%s] %s', $stream->pid, $chunk ) );
            },
            close => sub {
                my ($stream) = @_;
                app->log->info( sprintf('[%s] end process', $stream->pid ) );
            },
        }

- timeout: _Scalar_

    [Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo::IOLoop::Stream) timeout attribute.

        timeout => 300

# AUTHOR

hayajo <hayajo@cpan.org>

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojo::IOLoop::Stream](https://metacpan.org/pod/Mojo::IOLoop::Stream)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
