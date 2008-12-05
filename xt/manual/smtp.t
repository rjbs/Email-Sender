use strict;
use warnings;

use Email::Sender::Transport::SMTP;

my $smtp = Email::Sender::Transport::SMTP->new;

my $message = <<'END';
From: RJ <rjbs+hdrF@pobox.com>
To: Rico <rjbs+hdr2@pobox.com>
Subject: test message

This is a test.

-- 
rjbs
END

my $result = $smtp->send(
  $message,
  {
    to   => 'rjbs+rcpt@pobox.com',
    from => 'rjbs+from@pobox.com',
  },
);

