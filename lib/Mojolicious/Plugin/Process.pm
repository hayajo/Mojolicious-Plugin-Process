{
    package Mojolicious::Plugin::Process;
    use Mojo::Base 'Mojolicious::Plugin';
    use Mojo::IOLoop;
    use Symbol ();
    use IPC::Open3 ();
    use Carp ();

    our $VERSION = '0.01';

    sub register {
        my ( $self, $app ) = @_;
        $app->helper( process => sub {
            my $c = shift;
            _process(@_);
        } );
    }

    sub _process {
        my $args = {@_};
        my $command = $args->{command} or Carp::croak "command was not specified";
        $command = [ $command ] if( ref($command) ne 'ARRAY');

        my ($stdin, $stdout, $stderr);
        $stderr = Symbol::gensym;
        my $pid = IPC::Open3::open3($stdin, $stdout, $stderr, @$command);

        my $stream_stdout = Mojo::IOLoop::Stream::Process->new($stdout);
        $stream_stdout->pid($pid);
        $stream_stdout->command($command);
        $stream_stdout->timeout( $args->{timeout} ) if defined $args->{timeout}; # default 15 sec (Mojo::IOLoop::Stream)
        for my $event ( keys %{ $args->{stdout} || {} } ) {
            $stream_stdout->on( $event => $args->{stdout}->{$event} );
        }
        # regist a default handler to stdout
        for my $event (qw{ close error timeout }) {
            $stream_stdout->on( $event => sub { shift->_finish(@_) } );
        }
        _watch($stream_stdout);

        if ( my $stderr_handler = $args->{stderr} ) {
            my $stream_stderr = Mojo::IOLoop::Stream::Process->new($stderr);
            $stream_stderr->pid($pid);
            $stream_stderr->command($command);
            $stream_stderr->timeout($stream_stdout->timeout);
            for my $event ( keys %{ $args->{stderr} || {} } ) {
                $stream_stderr->on( $event => $args->{stderr}->{$event} );
            }
            _watch($stream_stderr);
        }

        return ($stream_stdout, $stdin);
    }

    sub _watch {
        my $stream = shift;
        my $id = Mojo::IOLoop->singleton->stream($stream);
        $stream->ioloop_id($id);
        $stream->on( close => sub {
            my $stream = shift;
            Mojo::IOLoop->singleton->remove($id);
        } );

    }
}

{
    package Mojo::IOLoop::Stream::Process;
    use Mojo::Base 'Mojo::IOLoop::Stream';

    has 'ioloop_id';
    has 'pid';
    has 'command';

    sub DESTROY {
        my $pid = $_[0]->pid;
        _sig_term($pid);
    }

    sub _finish {
        my $pid = $_[0]->pid;
        _sig_term($pid);
    }

    sub _sig_term {
        my $pid = shift // return;
        kill 'TERM', $pid if ( kill( 0, $pid ) );
    }
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Process - execute a non-blocking command

=head1 SYNOPSIS

  # Mojolicious
  sub stratup {
    my $self = shift;
    $self->plugin('Process');
    ...
  }

  # Mojolicious::Lite
  plugin 'Process';

  # in controller
  get '/job' => sub {
      my $c = shift;
      my $job_id = MyApp->create_id( $c->req->params->to_hash );
      $c->stash( id => $job_id );
      $c->render('accept');

      if ($job_id) {
          # async execution of time-consuming process
          $c->process(
              command => [ 'job-command', 'id', $job_id ],
              stdtout => {
                  close  => sub {
                      my ($stream) = @_;
                      app->log->info( sprintf('[%s] end job', $stream->pid );
                  },
              },
              stdterr => {
                  read  => sub {
                      my ($stream, $chunk) = @_;
                      chomp $chunk;
                      app->log->err( sprintf('[%d] %s', $stream->pid, $chunk );
                  },
              },
              timeout => 0,
          );
      }
  };

=head1 DESCRIPTION

Mojolicious::Plugin::Process is a plugin for Mojolicious apps to execute a non-blocking command.

=head1 METHODS

L<Mojolicious::Plugin::Process> inherits all methods from L<Mojolicious::Plugin>.

=head1 HELPERS

L<Mojolicious::Plugin::Process> contains a helper: I<process>.

=head2 C<process>

  my ($stream, $stdin) = $self->process(
      command => [ 'job-command', 'id', $job_id ],
      stdtout => {
          read => sub {
              my ($stream, $chunk) = @_;
              chomp $chunk;
              app->log->info( sprintf('[%s] %s', $stream->pid, $chunk );
          },
          close => sub {
              my ($stream) = @_;
              app->log->info( sprintf('[%s] end process', $stream->pid );
          },
      },
      timeout => 0,
  );

=head3 ARGUMENTS

C<process> supports the following arguments

=over 4

=item * command: I<ArrayRef>

command. this is requried argument.

  command => [ 'echo', 'foo' ]

=item * stdout: I<HashRef>, stderr: I<HashRef>

can emit the following L<Mojo::IOLoop::Stream> events.

C<close>, C<error>, C<read>, C<timeout>

in handler, C<$stream> is a L<Mojo::IOLoop::Stream::Process> Ojbect.

L<Mojo::IOLoop::Stream::Process> has the following attributes.

C<ioloop_id>, C<pid>, C<command>

 stdtout => {
     read => sub {
         my ($stream, $chunk) = @_;
         chomp $chunk;
         app->log->info( sprintf('[%s] %s', $stream->pid, $chunk );
     },
     close => sub {
         my ($stream) = @_;
         app->log->info( sprintf('[%s] end process', $stream->pid );
     },
 }

=item * timeout: I<Scalar>

L<Mojo::IOLoop::Stream> timeout attribute.

  timeout => 300

=back

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop::Stream>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
