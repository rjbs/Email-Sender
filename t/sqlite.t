#!perl
use strict;
use warnings;

use Test::More tests => 5;
use File::Spec;
use File::Temp;

use Email::Sender::Transport::SQLite;

my $db = File::Spec->catfile(
  File::Temp::tempdir(CLEANUP => 1),
  'email.db',
);

my $sender = Email::Sender::Transport::SQLite->new({ db_file => $db });
isa_ok($sender, 'Email::Sender::Transport');
isa_ok($sender, 'Email::Sender::Transport::SQLite');

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
    {
      to   => 'recipient@nowhere.example.net',
      from => 'nobody@nowhere.example.mil',
    }
  );

  ok($result, 'success');
}

{
  my $result = $sender->send(
    $message,
    {
      to   => [
        qw(recipient@nowhere.example.net dude@los-angeles.ca.mil)
      ],
      from => 'nobody@nowhere.example.mil',
    }
  );

  ok($result, 'success');
}

my $dbh = DBI->connect("dbi:SQLite:dbname=$db", undef, undef);

my ($deliveries) = $dbh->selectrow_array("SELECT COUNT(*) FROM recipients");

is($deliveries, 3, "we delivered to 3 addresses");
