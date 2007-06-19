
use strict;
use warnings;

use Test::More 'no_plan';

use Email::Sender;
BEGIN { use_ok('Email::Sender::DevNull'); }

my $mailer = Email::Sender::DevNull->new;
isa_ok($mailer, 'Email::Sender');
isa_ok($mailer, 'Email::Sender::DevNull');

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

my $result = $mailer->send($message);
isa_ok($result, 'Email::Sender::Success');
