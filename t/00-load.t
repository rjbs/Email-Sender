use Test::More tests => 14;

BEGIN {
  use_ok('Email::Sender');
  use_ok('Email::Sender::DevNull');
  use_ok('Email::Sender::Failable');
  use_ok('Email::Sender::IOAll');
  use_ok('Email::Sender::Maildir');
  use_ok('Email::Sender::NNTP');
  use_ok('Email::Sender::OldSMTP');
  use_ok('Email::Sender::Qmail');
  use_ok('Email::Sender::SMTP');
  use_ok('Email::Sender::SQLite');
  use_ok('Email::Sender::STDOUT');
  use_ok('Email::Sender::Sendmail');
  use_ok('Email::Sender::Test');
  use_ok('Email::Sender::Wrapper');
}

diag( "Testing Email::Sender $Email::Sender::VERSION" );
