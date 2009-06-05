#!perl
use strict;
use warnings;
use Test::More 'no_plan';

$ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
use Email::Sender::Simple;

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

my $deliveries = Email::Sender::Simple->_default_transport->deliveries;

is(@$deliveries, 1, "we sent one message");

is_deeply(
  $deliveries->[0]->{envelope},
  {
    to   => [ 'number.2@green.dome.il' ],
    from => 'number.5@gov.uk',
  },
  "correct envelope deduced from message",
);
