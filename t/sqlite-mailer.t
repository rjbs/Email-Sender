
use strict;
use warnings;

use Test::More tests => 6;

use Email::Sender;
BEGIN { use_ok('Email::Sender::SQLite'); }

unlink 't/email.db';

my $mailer = Email::Sender::SQLite->new({ db_file => 't/email.db' });
isa_ok($mailer, 'Email::Sender');
isa_ok($mailer, 'Email::Sender::SQLite');

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
    {
      to   => [ qw(recipient@nowhere.example.net)],
      from => 'nobody@nowhere.example.mil',
    }
  );

  isa_ok($result, 'Email::Sender::Success');
}

{
  my $result = $mailer->send(
    $message,
    {
      to   => [
        qw(recipient@nowhere.example.net dude@los-angeles.ca.mil)
      ],
      from => 'nobody@nowhere.example.mil',
    }
  );

  isa_ok($result, 'Email::Sender::Success');
}

my $dbh = DBI->connect("dbi:SQLite:dbname=t/email.db", undef, undef);

my ($deliveries) = $dbh->selectrow_array("SELECT COUNT(*) FROM recipients");

is($deliveries, 3, "we delivered to 3 addresses");
