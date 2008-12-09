#!perl
use strict;
use warnings;
use Test::More tests => 2;

use Email::Sender::Transport;
use Email::Sender::Util;

my $message = <<'END';
From: "Ricardo O'Signes" <rjbs@example.com>
To: dude@example.com, <guy@example.com>, "I'm Not Your" <buddy@example.ca>
Cc: another <dude@example.com>, cc@cc.example.cc
Subject: sometimes people do dumb things
Cc: like <multiple@example.cc>
Bcc: bcc@example.biz

This is a test message.

-- 
rjbs
END

my $email = Email::Sender::Transport->prepare_email(\$message);

is_deeply(
  Email::Sender::Util->sender_from_email($email),
  'rjbs@example.com',
  "we get the sender we expect",
);

is_deeply(
  [ sort @{ Email::Sender::Util->recipients_from_email($email) } ],
  [ sort qw(dude@example.com guy@example.com buddy@example.ca cc@cc.example.cc
    multiple@example.cc bcc@example.biz) ],
  "we get the rcpts we expect",
);
