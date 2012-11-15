use inc::Module::Install;
use Module::Install::Repository;
name 'Mojolicious-Plugin-Process';
all_from 'lib/Mojolicious/Plugin/Process.pm';

# Windows unsupported
if ( $^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys' ) {
    die "$^O unsupported";
}

requires 'Mojolicious' => 3.02;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Capture::Tiny';

auto_set_repository;
auto_include;
WriteAll;
