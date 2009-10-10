use Test::More tests => 5;
use strict;
$^W = 1;

use Capture::Tiny 'capture';
use Cwd;
use Config;
use Email::Sender::Transport::Sendmail;
use File::Spec;

my $IS_WIN32 = $^O eq 'MSWin32';

my $email = <<'EOF';
To:   Casey West <casey@example.com>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

my @to_unlink;
END { unlink @to_unlink }

sub get_bin_name {
  return 'sendmail.bat' if $IS_WIN32;

  my ($bin_path) = @_;
  my $input_file = File::Spec->catfile( $bin_path, 'sendmail' );
  my $fn = "sendmail-$$-$^T.tmp";
  my $output_file = File::Spec->catfile( $bin_path, $fn );

  open my $in_fh,  '<', $input_file  or die "can't read input sendmail: $!";
  open my $out_fh, '>', $output_file or die "can't write temp sendmail: $!";

  while (<$in_fh>) {
    s/\A#!perl$/#!$^X/;
    print $out_fh $_;
  }

  push @to_unlink, $output_file;

  return $fn;
}

my $bin_path = File::Spec->rel2abs('util');
my $bin_name = get_bin_name($bin_path);
my $sendmail_bin = File::Spec->catfile( $bin_path, $bin_name );
local $ENV{PATH} = join( $Config{path_sep}, $bin_path, $ENV{PATH});

SKIP:
{
  chmod 0755, $sendmail_bin;
  skip "Cannot run unless '$sendmail_bin' is executable", 1
    unless -x $sendmail_bin;

  my $path = eval { 
    Email::Sender::Transport::Sendmail->_find_sendmail($bin_name) 
  };
  is( $path, $sendmail_bin, "found (fake) sendmail at '$sendmail_bin'" );
}

{
  my $sender = Email::Sender::Transport::Sendmail->new({
    sendmail => File::Spec->catfile(qw/. util not-executable/)
  });

  capture { # hide errors from cmd.exe on Win32
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
  };

  my $error_re = $IS_WIN32 ? qr/closing pipe/ : qr/open pipe/;
  like(
    $@->message,
    $error_re,
    'error message says what we expect',
  );
}

my $has_FileTemp = eval { require File::Temp; };

SKIP:
{
  skip 'Cannot run this test unless current perl is -x', 1 unless -x $^X;

  my $sender = Email::Sender::Transport::Sendmail->new({
    sendmail => $sendmail_bin
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

  skip 'Cannot run this test without File::Temp', 2 unless $has_FileTemp;
  my $tempdir = File::Temp::tempdir(CLEANUP => 1);
  my $logfile  = File::Spec->catfile($tempdir, 'sendmail.log');

  local $ENV{EMAIL_SENDER_TRANSPORT_SENDMAIL_TEST_LOGDIR} = $tempdir;
  my $sender = Email::Sender::Transport::Sendmail->new({
    sendmail => $sendmail_bin
  });

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
