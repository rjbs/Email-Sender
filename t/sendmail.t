use Test::More tests => 5;
use strict;
$^W = 1;

use Cwd;
use Email::Sender::Transport::Sendmail;
use File::Spec;

my $email = <<'EOF';
To:   Casey West <casey@example.com>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

SKIP:
{
  skip 'Cannot run unless sendmail is at /usr/sbin/sendmail', 1
    unless -x '/usr/sbin/sendmail'
      && ! -x '/usr/bin/sendmail';

  local $ENV{PATH} = '/usr/bin:/usr/sbin';
  $ENV{PATH} =~ tr/:/;/ if $^O =~ /Win/;
  my $path = Email::Sender::Transport::Sendmail->_find_sendmail;
  is( $path, '/usr/sbin/sendmail', 'found sendmail in /usr/sbin' );
}

{
  my $sender = Email::Sender::Transport::Sendmail->new({
    sendmail => './util/not-executable'
  });

  eval {
    no warnings;
    $sender->send(
      $email,
      {
        to   => [ 'devnull@example.com' ],
        from => 'devnull@example.biz',
      }
    );
  };

  like(
    $@->message,
    qr/couldn't open pipe/,
    'error message says what we expect',
  );
}

my $has_FileTemp = eval { require File::Temp; };

SKIP:
{
  skip 'Cannot run this test unless current perl is -x', 1 unless -x $^X;
  skip 'Win32 does not understand shebang', 1 if $^O eq 'MSWin32';

  skip 'Cannot run this test without File::Temp', 1 unless $has_FileTemp;
  my $tempdir = File::Temp::tempdir(CLEANUP => 1);

  require File::Spec;

  my $error = "can't prepare executable test script";

  my $filename = File::Spec->catfile($tempdir, "executable");
  open my $fh, ">", $filename or skip "$error: opening $filename", 1;

  open my $exec, "<", './util/executable' or skip $error, 1;

  print {$fh} "#!$^X\n" or skip "$error: outputting shebang", 1;
  print {$fh} <$exec>   or skip "$error: outputting body", 1;
  close $fh             or skip "$error: closing", 1;

  chmod 0755, $filename;

  my $sender = Email::Sender::Transport::Sendmail->new({
    sendmail => $filename
  });

  my $return = $sender->send(
    $email,
    {
      to   => [ 'devnull@example.com' ],
      from => 'devnull@example.biz',
    }
  );

  ok( $return, 'send() succeeded with executable $SENDMAIL' );
}

SKIP:
{
  skip 'Cannot run this test unless current perl is -x', 2 unless -x $^X;
  skip 'Win32 does not understand shebang', 2 if $^O eq 'MSWin32';

  skip 'Cannot run this test without File::Temp', 2 unless $has_FileTemp;
  my $tempdir = File::Temp::tempdir(CLEANUP => 1);

  my $error = "can't prepare executable test script";

  my $filename = File::Spec->catfile($tempdir, 'sendmail');
  my $logfile  = File::Spec->catfile($tempdir, 'sendmail.log');
  open my $sendmail_fh, ">", $filename or skip $error, 2;
  open my $template_fh, "<", './util/sendmail' or skip $error, 2;

  print {$sendmail_fh} "#!$^X\n"      or skip $error, 2;
  print {$sendmail_fh} <$template_fh> or skip $error, 2;
  close $sendmail_fh                  or skip $error, 2;

  chmod 0755, $filename;

  local $ENV{PATH} = $tempdir;
  local $ENV{EMAIL_SENDER_TRANSPORT_SENDMAIL_TEST_LOGDIR} = $tempdir;
  my $sender = Email::Sender::Transport::Sendmail->new;
  my $return = eval {
    $sender->send(
      $email,
      {
        to   => [ 'devnull@example.com' ],
        from => 'devnull@example.biz',
      }
    );
  };

  ok( $return, 'send() succeeded with executable sendmail in path' );

  if (-f $logfile) {
    open my $fh, '<', $logfile
        or die "Cannot read $logfile: $!";
    my $log = join '', <$fh>;
    like($log, qr/From: Casey West/, 'log contains From header');
  } else {
    fail('cannot check sendmail log contents');
  }
}
