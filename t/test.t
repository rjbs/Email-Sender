#!perl
use strict;
use warnings;

use Test::More tests => 42;

use Email::Sender::Transport::Test;
use Email::Sender::Transport::Failable;

my $sender = Email::Sender::Transport::Test->new;
ok($sender->does('Email::Sender::Transport'));
isa_ok($sender, 'Email::Sender::Transport::Test');

is($sender->delivery_count, 0, "no deliveries so far");

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

ok($sender->is_simple,               "we can use standard Test for Simple");
ok(! $sender->allow_partial_success, "std Test doesn't allow partial succ");

{
  my $result = $sender->send(
    $message,
    { to => [ qw(recipient@nowhere.example.net) ] }
  );

  ok($result, 'success');
}

is($sender->delivery_count, 1, "we've done one delivery so far");

{
  my $result = $sender->send(
    $message,
    { to => [ qw(secret-bcc@nowhere.example.net) ] }
  );

  ok($result, 'success');
}

is($sender->delivery_count, 2, "we've done two deliveries so far");

my @deliveries = $sender->deliveries;

is_deeply(
  $deliveries[0]{successes},
  [ qw(recipient@nowhere.example.net)],
  "first message delivered to 'recipient'",
);

is_deeply(
  $deliveries[1]{successes},
  [ qw(secret-bcc@nowhere.example.net)],
  "second message delivered to 'secret-bcc'",
);

####

{
  package Email::Sender::Transport::TestFail;
  use Moose;
  extends 'Email::Sender::Transport::Test';

  sub delivery_failure {
    my ($self, $email, $env) = @_;
    return Email::Sender::Failure->new('bad sender')
      if $env->{from} =~ /^reject@/;
    return;
  }

  sub recipient_failure {
    my ($self, $rcpt) = @_;

    if ($rcpt =~ /^fault@/) {
      return Email::Sender::Failure->new({
        message    => 'fault',
        recipients => [ $rcpt ],
      });
    }

    if ($rcpt =~ /^tempfail@/) {
      return Email::Sender::Failure::Temporary->new({
        message    => 'tempfail',
        recipients => [ $rcpt ],
      });
    }

    if ($rcpt =~ /^permfail@/) {
      return Email::Sender::Failure::Permanent->new({
        message    => 'permfail',
        recipients => [ $rcpt ],
      });
    }

    return;
  }

  no Moose;
}

my $fail_test = Email::Sender::Transport::TestFail->new;

sub test_fail {
  my ($env, $succ_cb, $fail_cb) = @_;

  my $ok    = eval { $fail_test->send($message, $env); };
  my $error = $@;

  $succ_cb ? $succ_cb->($ok)    : ok(! $ok,    'we expected to fail');
  $fail_cb ? $fail_cb->($error) : ok(! $error, 'we expected to succeed');
}

test_fail(
  {
    to   => 'ok@example.com',
    from => 'sender@example.com',
  },
  sub { ok(ref $_[0] eq 'Email::Sender::Success', 'correct success class'); },
  undef,
);

test_fail(
  {
    to   => 'ok@example.com',
    from => 'reject@example.com',
  },
  undef,
  sub {
    my ($fail) = @_;

    isa_ok($fail, 'Email::Sender::Failure');
    is($fail->message, 'bad sender', 'got expected failure message');
    is_deeply(
      [ $fail->recipients ],
      [ 'ok@example.com' ],
      'correct recipients on failure notice',
    );
  },
);

test_fail(
  {
    to   => 'tempfail@example.com',
    from => 'sender@example.com',
  },
  undef,
  sub { isa_ok($_[0], 'Email::Sender::Failure::Temporary'); },
);

test_fail(
  {
    to   => 'permfail@example.com',
    from => 'sender@example.com',
  },
  undef,
  sub { isa_ok($_[0], 'Email::Sender::Failure::Permanent'); },
);

test_fail(
  {
    to   => 'fault@example.com',
    from => 'sender@example.com',
  },
  undef,
  sub { is(ref $_[0], 'Email::Sender::Failure', 'exact class on fault'); },
);

test_fail(
  {
    to   => [ 'permfail@example.com', 'ok@example.com' ],
    from => 'sender@example.com',
  },
  undef,
  sub {
    my $fail = shift;
    isa_ok($fail, 'Email::Sender::Failure', 'we got a failure');
    isa_ok($fail, 'Email::Sender::Failure::Multi', "it's a multifailure");
    my @failures = $fail->failures;
    is(@failures, 1, "there is only 1 failure in our multi");
    is_deeply(
      [ $fail->recipients ],
      [ 'permfail@example.com' ],
      'failing addrs are correct',
    );
    ok(
      $fail->isa('Email::Sender::Failure::Permanent'),
      "even though it is a Multi, we report isa Permanent since it's uniform",
    );
  },
);

$fail_test = Email::Sender::Transport::TestFail->new({
  allow_partial_success => 1,
});

ok(! $fail_test->is_simple,           "partial success capable Test ! simple");
ok($fail_test->allow_partial_success, "...becaue it allows partial success");

test_fail(
  {
    to   => [ 'permfail@example.com', 'ok@example.com' ],
    from => 'sender@example.com',
  },
  sub {
    my $succ = shift;
    isa_ok($succ, 'Email::Sender::Success', 'we got a success');
    isa_ok($succ, 'Email::Sender::Success::Partial', "it's partial");
    my $failure = $succ->failure;
    isa_ok($failure, 'Email::Sender::Failure::Multi', 'the failure is multi');

    my @failures = $failure->failures;
    is(@failures, 1, "there is only 1 failure in our partial");

    is_deeply(
      [ $succ->failure->recipients ],
      [ 'permfail@example.com' ],
      'failing addrs are correct',
    );
    ok(
      ! $succ->isa('Email::Sender::Failure::Permanent'),
      "we do not crazily report the success ->isa permfail",
    );
  },
  undef,
);

####

my $failer = Email::Sender::Transport::Failable->new({ transport => $sender });
$failer->transport->clear_deliveries;

my $i = 0;
$failer->fail_if(sub {
  return "failing half of all mail to test" if $i++ % 2;
  return;
});

{
  my $result = eval { $failer->send($message, { to => [ qw(ok@ok.ok) ] }) };
  ok($result, 'success');
}

is(
  $failer->transport->delivery_count,
  1,
  "first post-fail_if delivery is OK"
);

{
  eval { my $result = $failer->send($message, { to => [ qw(ok@ok.ok) ] }) };
  isa_ok($@, 'Email::Sender::Failure', "we died");
}

is(
  $failer->transport->delivery_count,
  1,
  "second post-fail_if delivery fails"
);
