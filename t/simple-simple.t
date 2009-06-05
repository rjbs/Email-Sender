#!perl
use strict;
use warnings;
use Test::More 'no_plan';

$ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
use Email::Sender::Simple qw(sendmail);

my $email = <<'.';
From: V <number.5@gov.uk>
To: II <number.2@green.dome.il>
Subject: jolly good show

Wot, wot!

-- 
v
.

my $result = Email::Sender::Simple->send($email);

isa_ok($result, 'Email::Sender::Success');

my $env_transport = Email::Sender::Simple->default_transport;
my $deliveries = $env_transport->deliveries;

is(@$deliveries, 1, "we sent one message");

is_deeply(
  $deliveries->[0]->{envelope},
  {
    to   => [ 'number.2@green.dome.il' ],
    from => 'number.5@gov.uk',
  },
  "correct envelope deduced from message",
);

{
  my $new_test = Email::Sender::Transport::Test->new;
  my $result   = Email::Sender::Simple->send(
    $email,
    {
      to   => 'devnull@example.com',
      transport => $new_test
    },
  );

  is(
    @{ $env_transport->deliveries },
    2,
    "we ignore the passed transport when we're using transport-from-env",
  );

  is_deeply(
    $deliveries->[1]->{envelope},
    {
      to   => [ 'devnull@example.com' ],
      from => 'number.5@gov.uk',
    },
    "we stored the right message for the second delivery",
  );
}

{
  my $email = Email::Simple->new("Subject: foo\n\nbar\n");

  {
    my $result = eval { Email::Sender::Simple->send($email); };
    isa_ok($@, 'Email::Sender::Failure', "we throw on failure");
    is($result, undef, "...meaning there is no return value");
  }

  {
    my $result = Email::Sender::Simple->try_to_send($email);
    ok(! $@, "no exception when we try_to_send and fail");
    ok(! $result, "...but we do get a false value");
  }
}
