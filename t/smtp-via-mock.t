#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
plan skip_all => 'Test::MockObject required to test SMTP transport by mocking'
  unless eval { require Test::MockObject };
}

use lib 't/lib';
use Test::Email::Sender::Util;

my $mock_smtp;
BEGIN {
  $mock_smtp = Test::MockObject->new;
  $mock_smtp->fake_module('Net::SMTP');
  $mock_smtp->fake_new('Net::SMTP');
  Test::Email::Sender::Util->perform_stock_mockery($mock_smtp);

  $mock_smtp->{pass}{rjbs} = 'natural20';

  $mock_smtp->{failaddr}{'tempfail@example.com'} = [ 401 => 'Temporary FOAD' ];
  $mock_smtp->{failaddr}{'permfail@example.com'} = [ 552 => 'Permanent FOAD' ];

  $mock_smtp->{failaddr}{'tempfail@example.net'} = [ 447 => 'Temporary STHU' ];
  $mock_smtp->{failaddr}{'permfail@example.net'} = [ 519 => 'Permanent STHU' ];
}

plan tests => 1;

use Email::Sender::Transport::SMTP;

my $sender  = Email::Sender::Transport::SMTP->new;
my $message = join '', @{ readfile('t/messages/simple.msg') };

sub test_smtp {
  my ($env, $succ_cb, $fail_cb) = @_;

  my $ok    = eval { $sender->send($message, $env); };
  my $error = $@;

  $succ_cb ? $succ_cb->($ok)    : ok(! $ok,    'we expected to fail');
  $fail_cb ? $fail_cb->($error) : ok(! $error, 'we expected to succeed');
}

test_smtp(
  {
    from => 'okay@example.net',
    to   => 'okay@example.com',
  },
  sub { isa_ok($_[0], 'Email::Sender::Success'); },
  undef,
);

test_smtp(
  {
    from => 'okay@example.net',
    to   => 'tempfail@example.com',
  },
  undef,
  sub {
    isa_ok($_[0], 'Email::Sender::Failure::Temporary');
  },
);

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
