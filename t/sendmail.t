#!perl
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Email::Sender::Sendmail'); }

my $mailer = Email::Sender::Sendmail->new;

isa_ok($mailer, 'Email::Sender');
isa_ok($mailer, 'Email::Sender::Sendmail');

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

{
  my $result = $mailer->send(
    $message,
    {
      from => 'devnull@pobox.com',
      to   => [ 'devnull@pobox.com' ],
    }
  );

  isa_ok($result, 'Email::Sender::Success');
}
