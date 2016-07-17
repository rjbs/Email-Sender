#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
plan skip_all => 'Test::MockObject required to test SMTP transport by mocking'
  unless eval { require Test::MockObject };

plan skip_all => 'Sub::Override required to test SMTP transport by mocking'
  unless eval { require Sub::Override };
}

use lib 't/lib';
use Test::Email::Sender::Util;

my $mock_smtp;
BEGIN {
  $mock_smtp = Test::MockObject->new;
  $mock_smtp->fake_module('Net::SMTP');
  $mock_smtp->fake_new('Net::SMTP');
  Test::Email::Sender::Util->perform_stock_mockery($mock_smtp);

  eval '$Net::SMTP::VERSION = "3.07"';

  $mock_smtp->{pass}{username} = 'password';

  $mock_smtp->{failaddr}{'tempfail@example.com'} = [ 401 => 'Temporary FOAD' ];
  $mock_smtp->{failaddr}{'permfail@example.com'} = [ 552 => 'Permanent FOAD' ];

  $mock_smtp->{failaddr}{'tempfail@example.net'} = [ 447 => 'Temporary STHU' ];
  $mock_smtp->{failaddr}{'permfail@example.net'} = [ 519 => 'Permanent STHU' ];
}

plan tests => 95;

use Email::Sender::Transport::SMTP;
use Email::Sender::Transport::SMTP::Persistent;

for my $class (qw(
  Email::Sender::Transport::SMTP
  Email::Sender::Transport::SMTP::Persistent
)) {
  our $sender  = $class->new;
  our $message = join '', @{ readfile('t/messages/simple.msg') };
  our $prefix = $class =~ /Persist/ ? 'pst' : 'std';
  our $test   = '(unknown test)';

  my $ok = Test::Builder->can('ok');
  my $override = Sub::Override->new(
    'Test::Builder::ok' => sub {
      my ($self, $t, $name) = @_;
      $name = '(no desc)' unless defined $name;
      $name = "$prefix/$test: $name";
      @_ = ($self, $t, $name);
      goto &$ok;
    }
  );

  sub test_smtp {
    my ($env, $succ_cb, $fail_cb) = @_;

    my $ok    = eval { $sender->send($message, $env); };
    my $error = $@;

    $succ_cb ? $succ_cb->($ok)    : ok(! $ok,    "$test: we expected to fail");
    $fail_cb ? $fail_cb->($error) : ok(! $error, "$test: we expected to succeed");
  }

  {
    local $test = 'conn. fail';
    my $no_smtp = Sub::Override->new('Net::SMTP::new' => sub { return });
    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub {
        isa_ok($_[0], 'Email::Sender::Failure');
        like("$_[0]", qr/unable to establish/, "we got a conn. fail");
      },
    );
  }

  {
    local $test = 'simple okay';
    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      sub { isa_ok($_[0], 'Email::Sender::Success'); },
      undef,
    );
  }

  {
    local $test = 'no valid rcpts';
    test_smtp(
      {
        from => 'okay@example.net',
        to   => [ '', undef ],
      },
      undef,
      sub {
        isa_ok($_[0], 'Email::Sender::Failure');
        like("$_[0]", qr{no valid address}, "got 0 valid addrs error");
      },
    );
  }

  {
    local $test = 'tempfail RCPT';
    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'tempfail@example.com',
      },
      undef,
      sub {
        isa_ok($_[0], 'Email::Sender::Failure::Temporary');
        is($_[0]->code, 401, 'got the right code in the exception');
      },
    );
  }

  {
    local $test = 'mixed RCPT results';

    test_smtp(
      {
        from => 'okay@example.net',
        to   => [
          'tempfail@example.com',
          'permfail@example.com',
          'okay@example.com',
        ],
      },
      undef,
      sub {
        my $fail = shift;
        isa_ok($fail, 'Email::Sender::Failure::Multi');
        ok(! $fail->isa('Email::Sender::Failure::Permanent'), 'failure <> Perm');
        ok(! $fail->isa('Email::Sender::Failure::Temporary'), 'failure <> Temp');
        is($fail->code, undef, 'no specific code on multifail');
        is_deeply(
          [ sort $fail->recipients ],
          [ qw(permfail@example.com tempfail@example.com) ],
          'the two failers failed',
        );
        my @failures = # sort { ($a->recipients)[0] cmp ($b->recipients)[0] }
                       $fail->failures;

        is(@failures, 2, "we got two failures");

        isa_ok($failures[0], 'Email::Sender::Failure::Temporary', '1st failure');
        isa_ok($failures[1], 'Email::Sender::Failure::Permanent', '2nd failure');
      },
    );
  }

  {
    local $test = 'multi tempfail RCPT';

    test_smtp(
      {
        from => 'okay@example.net',
        to   => [
          'tempfail@example.com',
          'tempfail@example.net',
        ],
      },
      undef,
      sub {
        my $fail = shift;
        isa_ok($fail, 'Email::Sender::Failure::Multi');
        isa_ok($fail, 'Email::Sender::Failure::Temporary');
        is_deeply(
          [ sort $fail->recipients ],
          [ qw(tempfail@example.com tempfail@example.net) ],
          'all rcpts failed',
        );
      },
    );
  }

  {
    local $test   = 'partial succ';
    local $sender = $class->new({
      allow_partial_success => 1
    });

    test_smtp(
      {
        from => 'okay@example.net',
        to   => [
          'tempfail@example.com',
          'permfail@example.com',
          'okay@example.com',
        ],
      },
      sub {
        isa_ok($_[0], 'Email::Sender::Success::Partial');
      },
      undef,
    );
  }

  {
    local $test = 'tempfail MAIL';
    test_smtp(
      {
        from => 'tempfail@example.com',
        to   => 'okay@example.com',
      },
      undef,
      sub { isa_ok($_[0], 'Email::Sender::Failure::Temporary'); },
    );
  }

  {
    local $test = 'permfail MAIL';
    test_smtp(
      {
        from => 'permfail@example.com',
        to   => 'okay@example.com',
      },
      undef,
      sub { isa_ok($_[0], 'Email::Sender::Failure::Permanent'); },
    );
  }

  {
    local $test   = 'auth okay';
    local $sender = $class->new({
      sasl_username => 'username',
      sasl_password => 'password',
    });

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      sub { isa_ok($_[0], 'Email::Sender::Success'); },
      undef,
    );
  }

  {
    local $test   = 'auth badpw';
    local $sender = $class->new({
      sasl_username => 'username',
      sasl_password => 'failword',
    });

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub { isa_ok($_[0], 'Email::Sender::Failure'); },
    );
  }

  {
    local $test   = 'auth unknown user';
    local $sender = $class->new({
      sasl_username => 'unknown',
      sasl_password => 'password',
    });

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub { isa_ok($_[0], 'Email::Sender::Failure'); },
    );
  }

  {
    local $test   = 'auth nopw';
    local $sender = $class->new({
      sasl_username => 'username',
    });

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub { isa_ok($_[0], 'Email::Sender::Failure'); },
    );
  }

  {
    local $test   = 'fail @ data start';
    local $mock_smtp->{datafail} = 'data';

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub {
        isa_ok($_[0], 'Email::Sender::Failure');
        like("$_[0]", qr{DATA start}, 'failed at correct phase');
      },
    );
  }

  {
    local $test   = 'fail during data';
    local $mock_smtp->{datafail} = 'datasend';

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub {
        isa_ok($_[0], 'Email::Sender::Failure');
        like("$_[0]", qr{during DATA}, 'failed at correct phase');
      },
    );
  }

  {
    local $test   = 'fail @ data end';
    local $mock_smtp->{datafail} = 'dataend';

    test_smtp(
      {
        from => 'okay@example.net',
        to   => 'okay@example.com',
      },
      undef,
      sub {
        isa_ok($_[0], 'Email::Sender::Failure');
        like("$_[0]", qr{after DATA}, 'failed at correct phase');
      },
    );
  }
}

subtest "quoteaddr" => sub {
  my @tests = qw(
    0 example
    0 o'neil
    0 ricardo.signes
    0 hot_coffee
    1 everybody;loves;ldap
    1 .emailrc
  );

  my $q = Email::Sender::Transport::SMTP->can('_quoteaddr');
  while (my ($quote, $local) = splice @tests, 0, 2) {
    my $input = qq{$local\@example.com};
    my $want  = $quote ? qq{"$local"\@example.com} : $input;

    is($q->(qq{$local\@example.com}), $want, "correct behavior for $local");
  }
};
