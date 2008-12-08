use strict;
use warnings;

use Data::Dumper;
use Email::Sender::Transport::SMTP;
use Email::Sender::Transport::SMTP_X;

for my $suffix ('', '_X') {
  my $class = "Email::Sender::Transport::SMTP$suffix";
  my $smtp  = $class->new({
    host => 'mx-all.pobox.com',
    allow_partial_success => 1,
  });

  my $message = <<'END';
From: RJ <rjbs+hdrF@pobox.com>
To: Rico <rjbs+hdr2@pobox.com>
Subject: test message

This is a test.

-- 
rjbs
END

  my $result = eval {
    $smtp->send(
      $message,
      {
        to   => [ 'rjjjjjjbs+rcpt@pobox.com', 'dfdfdasdfase@pobox.com' ],
        from => 'rjbs+from@pobox.com',
      },
    );
  };

  print "\n\n$class - " . Dumper($result || $@) . "\n\n";
}
