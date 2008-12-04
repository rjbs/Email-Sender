
use strict;
use warnings;

use Test::More tests => 20;

use Email::Sender::Transport::Test;

my $sender = Email::Sender::Transport::Test->new;
isa_ok($sender, 'Email::Sender::Transport');
isa_ok($sender, 'Email::Sender::Transport::Test');

is($sender->deliveries, 0, "no deliveries so far");

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
  my $result = $sender->send(
    $message,
    { to => [ qw(recipient@nowhere.example.net) ] }
  );

  ok($result, 'success');
}

is($sender->deliveries, 1, "we've done one delivery so far");

{
  my $result = $sender->send(
    $message,
    { to => [ qw(secret-bcc@nowhere.example.net) ] }
  );

  ok($result, 'success');
}

is($sender->deliveries, 2, "we've done two deliveries so far");

my @deliveries = $sender->deliveries;

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

$sender->bad_recipients([ qr/bad-example/ ]);

{
  my $result = eval {
    $sender->send(
      $message,
      { to => [ qw(mr.bad-example@nowhere.example.net)] }
    );
  };

  my $error = $@;

  ok(! $result, "mailing failed completely");
  isa_ok($error, 'Email::Sender::Failure');

  is_deeply(
    $error->failures,
    [ {
      to    => 'mr.bad-example@nowhere.example.net',
      type  => 'permanent',
      error => 'bad recipient',
    } ],
    "delivery indicates failure to 'mr.bad-example'",
  );
}

is($sender->deliveries, 2, "we've done three deliveries so far");

####

use_ok('Email::Sender::Transport::Failable');

my $failer = Email::Sender::Transport::Failable->new({ transport => $sender });

my $i = 0;
$failer->fail_if(sub { return 1 if $i++ % 2 });

is(
  $failer->failure_conditions,
  1,
  "we're now failing on every other delivery",
);

{
  my $result = eval { $failer->send($message, { to => [ qw(ok@ok.ok) ] }) };
  ok($result, 'success');
}

is($failer->transport->deliveries, 3, "first post-fail_if delivery is OK");

{
  eval { my $result = $failer->send($message, { to => [ qw(ok@ok.ok) ] }) };
  ok($@, "we died"); # XXX lame -- rjbs, 2007-02-16
}

is($failer->transport->deliveries, 3, "second post-fail_if delivery fails");
