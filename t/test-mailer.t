
use strict;
use warnings;

use Test::More tests => 21;

use Email::Sender;
BEGIN { use_ok('Email::Sender::Test'); }

my $mailer = Email::Sender::Test->new;
isa_ok($mailer, 'Email::Sender');
isa_ok($mailer, 'Email::Sender::Test');

is($mailer->deliveries, 0, "no deliveries so far");

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
    { to => [ qw(recipient@nowhere.example.net) ] }
  );

  isa_ok($result, 'Email::Sender::Success');
}

is($mailer->deliveries, 1, "we've done one delivery so far");

{
  my $result = $mailer->send(
    $message,
    { to => [ qw(secret-bcc@nowhere.example.net) ] }
  );

  isa_ok($result, 'Email::Sender::Success');
}

is($mailer->deliveries, 2, "we've done two deliveries so far");

my @deliveries = $mailer->deliveries;

is_deeply(
  $deliveries[0]{successes},
  [ qw(recipient@nowhere.example.net)],
  "first message delivered to 'recipient'",
);

is_deeply(
  $deliveries[1]{successes},
  [ qw(secret-bcc@nowhere.example.net)],
  "second message delivered to 'secret-bcc'",
);

$mailer->bad_recipients([ qr/bad-example/ ]);

{
  my $result = $mailer->send(
    $message,
    { to => [ qw(mr.bad-example@nowhere.example.net)] }
  );

  isa_ok($result, 'Email::Sender::Success');

  is_deeply(
    $result->failures,
    { 'mr.bad-example@nowhere.example.net' => 'bad recipient' },
    "delivery indicates failure to 'mr.bad-example'",
  );
}

is($mailer->deliveries, 3, "we've done three deliveries so far");

@deliveries = $mailer->deliveries;

is_deeply(
  $deliveries[2]{successes},
  [ ],
  "third message delivered to no one",
);

is_deeply(
  $deliveries[2]{failures},
  { 'mr.bad-example@nowhere.example.net' => 'bad recipient' },
  "third message failed to 'mr.bad-example'",
);

####

use_ok('Email::Sender::Failable');

my $failer = Email::Sender::Failable->new({ mailer => $mailer });

my $i = 0;
$failer->fail_if(sub { return 1 if $i++ % 2 });

is(
  $failer->failure_conditions,
  1,
  "we're now failing on every other delivery",
);

{
  my $result = $failer->send($message, { to => [ qw(ok@ok.ok) ] });
  isa_ok($result, 'Email::Sender::Success');
}

is($failer->deliveries, 4, "first post-fail_if delivery is OK");

{
  eval { my $result = $failer->send($message, { to => [ qw(ok@ok.ok) ] }) };
  ok($@, "we died"); # XXX lame -- rjbs, 2007-02-16
}

is($failer->deliveries, 4, "second post-fail_if delivery fails");
