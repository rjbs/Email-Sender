use Test::More tests => 6;
use strict;
$^W = 1;

use Cwd;
use_ok('Email::Sender::Sendmail');

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
  my $path = Email::Sender::Sendmail->_find_sendmail;
  is( $path, '/usr/sbin/sendmail', 'found sendmail in /usr/sbin' );
}

{
  my $sender = Email::Sender::Sendmail->new({
    sendmail => './util/not-executable'
  });

  eval { $sender->send($email); };
  like($@, qr/couldn't open pipe/, 'error message says what we expect' );
}

my $has_FileTemp = eval { require File::Temp; };

SKIP:
{
  skip 'Cannot run this test unless current perl is -x', 1 unless -x $^X;
  skip 'Win32 does not understand shebang', 1 if $^O eq 'MSWin32';

  skip 'Cannot run this test without File::Temp', 1 unless $has_FileTemp;
  my $tempdir = File::Temp::tempdir(DIR => 't', CLEANUP => 1);

  require File::Spec;

  my $error = "can't prepare executable test script";

  my $filename = File::Spec->catfile($tempdir, "executable");
  open my $fh, ">", $filename or skip "$error: opening $filename", 1;

  open my $exec, "<", './util/executable' or skip $error, 1;

  print {$fh} "#!$^X\n" or skip "$error: outputting shebang", 1;
  print {$fh} <$exec>   or skip "$error: outputting body", 1;
  close $fh             or skip "$error: closing", 1;

  chmod 0755, $filename;

  my $sender = Email::Sender::Sendmail->new({ sendmail => $filename });
  my $return = $sender->send($email);
  ok( $return, 'send() succeeded with executable $SENDMAIL' );
}

SKIP:
{
  skip 'Cannot run this test unless current perl is -x', 2 unless -x $^X;
  skip 'Win32 does not understand shebang', 2 if $^O eq 'MSWin32';

  skip 'Cannot run this test without File::Temp', 2 unless $has_FileTemp;
  my $tempdir = File::Temp::tempdir(DIR => 't', CLEANUP => 1);

  require File::Spec;

  my $error = "can't prepare executable test script";

  my $filename = File::Spec->catfile($tempdir, "sendmail");
  open my $sendmail_fh, ">", $filename or skip $error, 2;
  open my $template_fh, "<", './util/sendmail' or skip $error, 2;

  print {$sendmail_fh} "#!$^X\n"      or skip $error, 2;
  print {$sendmail_fh} <$template_fh> or skip $error, 2;
  close $sendmail_fh                  or skip $error, 2;

  chmod 0755, $filename;

  local $ENV{PATH} = $tempdir;
  my $sender = Email::Sender::Sendmail->new;
  my $return = eval { $sender->send($email) };
  ok( $return, 'send() succeeded with executable sendmail in path' );

  if ( -f 'sendmail.log' ) {
    open my $fh, '<sendmail.log'
        or die "Cannot read sendmail.log: $!";
    my $log = join '', <$fh>;
    like( $log, qr/From: Casey West/, 'log contains From header' );
  } else {
    fail( 'cannot check sendmail log contents'  );
  }
}
