use strict;
use warnings;

use Email::Sender::Transport::SMTP;
use Email::Sender::Transport::SMTP_X;

for my $suffix ('', '_X') {
  my $class = "Email::Sender::Transport::SMTP$suffix";
  my $smtp  = $class->new;

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

  print "$class - $result\n";
}
