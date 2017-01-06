#!perl -w
use strict;
use warnings;

use Test::More tests => 2;

use Email::Sender::Simple;
use Email::Sender::Transport::Test;

my $transport = Email::Sender::Transport::Test->new();

{
    my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: =?UTF-8?Q?=22J=C3=A9r=C3=B4me_=C3=89t=C3=A9v=C3=A9=22_=3Crecipient=40nowh?=
 =?UTF-8?Q?ere=2Eexample=2Enet=3E?=
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

    Email::Sender::Simple->send(
        $message,
        { transport => $transport }
    );
    my @deliveries = $transport->deliveries;
    is_deeply(
        $deliveries[0]{successes},
        [ qw(recipient@nowhere.example.net)],
        "first message delivered to 'recipient'",
    );
}

{
    my $message = <<'END_MESSAGE';
From: sender@test.example.com
Cc: "Another Recipient" <anotherrecipient@nowhere.example.net>
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

    Email::Sender::Simple->send(
        $message,
        { transport => $transport }
    );
    my @deliveries = $transport->deliveries;
    is_deeply(
        $deliveries[1]{successes},
        [ qw(anotherrecipient@nowhere.example.net)],
        "first message delivered to 'recipient'",
    );
}

