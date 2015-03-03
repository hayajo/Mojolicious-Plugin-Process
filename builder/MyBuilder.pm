package builder::MyBuilder;

use strict;
use warnings;

use parent 'Module::Build';

sub ACTION_build {
    die "The operating system is some version of Microsoft Windows"
      if ( $^O =~ m/Cygwin|MSWin32/ );

    $_[0]->SUPER::ACTION_build(@_);
}

1;
