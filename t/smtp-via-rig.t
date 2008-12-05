#!perl
use strict;
use warnings;
use Test::More;

my $env_str = $ENV{EMAIL_SENDER_SMTPRIGS} || $ENV{EMAIL_SENDER_SMTPRIGS};

plan skip_all => 'set EMAIL_SENDER_SMTPRIGS to run these tests' if ! $env_str;

plan skip_all => 'JSON required to run these tests'
  unless eval { require JSON; 1 };

use lib 't/lib';
use Test::Email::Sender::Util;
use Test::Email::SMTPRig;
use Email::Sender::Transport::SMTP;

my @rigs = split /\s+/, $env_str;

my $tests_per_rig = 3;

plan tests => $tests_per_rig * @rigs;

my $stock_message = <<'END';
Subject: this message sent by perl module Test::Email::SMTPRig
Message-Id: <%s@%s>
From: "Test::Email::SMTPRig" <devnull@%s.example.com>
To:   "Test::Email::SMTPRig Server" <devnull@%s.example.com>

This message body is unimportant.

The message-id is included in the body to get a unique md5sum:

  <%s@%s>

-- 
the perl email project
END

my $message_counter = 0;

for my $rig_conf (@rigs) {
  my $lines = readfile($rig_conf);
  my $json  = join '', @$lines;
  my $conf  = JSON->new->decode($json);
  my ($class, $args, $tests) = @$conf;

  my $rig = $class->new($args);
  isa_ok($rig, 'Test::Email::SMTPRig');

  my $sender = Email::Sender::Transport::SMTP->new({
    host => $rig->smtp_host,
    port => $rig->smtp_port,
    ssl  => $rig->smtp_ssl,
    helo => $rig->client_id,
  });

  for my $test (@$tests) {
    $rig->prep_next_transaction($test);

    # XXX: rigs need a way to provide their own messages -- rjbs, 2008-12-05
    $message_counter++;
    my $message = sprintf $stock_message,
      $message_counter, $rig->client_id,
      $rig->client_id,
      $rig->client_id,
      $message_counter, $rig->client_id,
    ;

    my $result = eval {
      $sender->send($message, { to => $test->{to}, from => $test->{from} });
    };

    my $error = $@;

    Carp::croak("should never happen: false result, no exception")
      unless $result or $error;

    my $result_class = $result ? ref $result : ref $error;

    is($result_class, $test->{result_class}, 'got correct result class');

    if ($rig->can('get_delivery_reports')) {
      my @reports = $rig->get_delivery_reports;
      ok(@reports, 'got delivery reports');
    } else {
      SKIP: {
        skip('this rig does not support checking delivery status', 1);
      };
    }
  }
}

