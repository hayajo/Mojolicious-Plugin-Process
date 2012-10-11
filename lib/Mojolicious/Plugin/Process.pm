{
    package Mojolicious::Plugin::Process;
    use Mojo::Base 'Mojolicious::Plugin';
    use Mojo::IOLoop;
    use Encode ();

    our $VERSION = '0.01';

    sub register {
        my ( $self, $app ) = @_;
        $app->helper( process => sub {
            my $c = shift;
            _process(@_);
        } );
    }

    sub _process {
        my $stream = Mojo::IOLoop::Stream::Process->new(@_);
        _watch($stream);
        return $stream;
    }

    sub _watch {
        my $stream = shift;
        my $id = Mojo::IOLoop->singleton->stream($stream);
        $stream->ioloop_id($id);
        $stream->on( close => sub {
            my $stream = shift;
            Mojo::IOLoop->singleton->remove( $stream->ioloop_id );
        } );
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

{
    package Mojo::IOLoop::Stream::Process;
    use Mojo::Base 'Mojo::IOLoop::Stream';
    has 'ioloop_id';
    has 'pid';
    has 'cmd';
    has 'cmd_args';

    sub new {
        my $class = shift;
        my $cmd   = shift;
        my $opts  = { @_ };

        my $pid = open( my $fh, '-|', $cmd, @{ $opts->{cmd_args} || [] } )
            // die "failed fork: " . Encode::decode_utf8($!);

        my $self = $class->SUPER::new($fh);
        $self->pid($pid);
        $self->cmd($cmd);
        $self->cmd_args( $opts->{cmd_args} );
        $self->timeout( $opts->{timeout} ) if defined $opts->{timeout}; # default 15 sec (Mojo::IOLoop::Stream)

        for my $event ( keys %{ $opts->{handler} || {} } ) {
            $self->on( $event => $opts->{handler}->{$event} );
        }

        # regist a default handler
        for my $event (qw{ close error timeout }) {
            $self->on( $event => sub { shift->_finish(@_) } );
        }

        return $self;
    }

    sub _finish {
        my $pid = shift->pid;
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
    $self->pulugin('Process');
    ...
  }

  # Mojolicious::Lite
  pulugin 'Process';

  # in controller
  get '/job' => sub {
      my $c = shift;
      my $job_id = MyApp->create_id( $c->req->params->to_hash );
      $c->stash( id => $job_id );
      $c->render('accept');

      if ($job_id) {
          # async execution of time-consuming process
          $c->process(
              './bin/do-job',
              cmd_args => [ (id => $job_id) ],
              handler  => {
                  close  => sub {
                      my ($stream) = @_;
                      app->log->info( sprintf('[%s] end job', $stream->pid );
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

  $self->process(
      './bin/do-job',
      cmd_args => [ (id => $job_id) ],
      handler  => {
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

=head3 OPTIONS

C<process> supports the following options.

=over 4

=item * cmd_args

B<ARRAYREF>

command arguments.

=item * handler

B<HASHREF>

can emit the following L<Mojo::IOLoop::Stream> events.

C<close>, C<error>, C<read>, C<timeout>

in handler, C<$stream> is a L<Mojo::IOLoop::Stream::Process> Ojbect.

L<Mojo::IOLoop::Stream::Process> has the following attributes.

C<ioloop_id>, C<pid>, C<cmd>, C<cmd_args>

=item * timeout

L<Mojo::IOLoop::Stream> timeout attribute.

=back

=head1 AUTHOR

hayajo E<lt>hayajo@cpan.orgE<gt>

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::IOLoop::Stream>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
