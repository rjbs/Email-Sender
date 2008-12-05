use strict;
use warnings;

use Email::Sender::Transport::SMTP;

my $smtp = Email::Sender::Transport::SMTP->new;

my $message = <<'END';
From: RJ <devnull+hdrF@pobox.com>
To: Rico <devnull+hdr2@pobox.com>
Subject: test message

This is a test.

-- 
rjbs
END

my $result = $smtp->send(
  $message,
  {
    to   => 'devnull+rcpt@pobox.com',
    from => 'devnull+from@pobox.com',
  },
);

