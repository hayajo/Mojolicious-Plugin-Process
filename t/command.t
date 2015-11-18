package Mojolicious::Plugin::Process::Command::Hello;
use Mojo::Base 'Mojolicious::Command';

sub run {
  my $self = shift;
  my ( $pid, $stdin ) = $self->app->process(
    command => [ qw/perl -e/, 'local $| = 1; sleep 3; print "Hello STDOUT"; print STDERR "Hello STDERR"' ],
    stdout  => {
      read => sub {
        my ($stream, $chunk) = @_;
        print "$chunk";
      },
    },
  );
}

package main;
use Mojo::Base qw{ -strict };
use Test::More tests => 1;
use Mojolicious;
use Mojolicious::Command;
use Capture::Tiny qw{ capture_stdout };

local $SIG{ALRM} = sub {
    BAIL_OUT("test failed. probably the problem happend in capture_stderr.");
};
alarm 10;

my $app = Mojolicious->new;
$app->plugin('Process');
$app->commands->namespaces(['Mojolicious::Plugin::Process::Command']);

my $stdout = capture_stdout {
  $app->start('Hello');
};
is $stdout, "Hello STDOUT";

done_testing;
