use Test::More tests => 1;

BEGIN {
  use_ok('Email::Sender');
}

diag( "Testing Email::Sender $Email::Sender::VERSION" );
