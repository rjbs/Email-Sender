#!perl
use strict;
use warnings;
use Test::More;

use lib 't/lib';

$ENV{EMAIL_SENDER_TRANSPORT} = 'Test::Email::Sender::Transport::FailEvery';
$ENV{EMAIL_SENDER_TRANSPORT_transport_class} = 'Test';
$ENV{EMAIL_SENDER_TRANSPORT_fail_every} = 2;
use Email::Sender::Simple qw(sendmail);

my $email = <<'.';
From: V <number.5@gov.uk>
To: II <number.2@green.dome.il>
Subject: jolly good show

Wot, wot!

-- 
v
.

subtest "first send: works" => sub {
  my $result = Email::Sender::Simple->send($email);

  isa_ok($result, 'Email::Sender::Success');

  my $env_transport = Email::Sender::Simple->default_transport;
  my @deliveries = $env_transport->transport->deliveries;

  is(@deliveries, 1, "we sent one message");

  is_deeply(
    $deliveries[0]->{envelope},
    {
      to   => [ 'number.2@green.dome.il' ],
      from => 'number.5@gov.uk',
    },
    "correct envelope deduced from message",
  );
};

subtest "second one: fails" => sub {
  my $ok    = eval { Email::Sender::Simple->send($email); };
  my $error = $@;
  ok( ! $ok, "it failed");
  isa_ok($error, 'Email::Sender::Failure');
};

done_testing;
