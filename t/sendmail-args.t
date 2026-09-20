use strict;
use warnings;

use Test::More;

use Email::Sender::Transport::Sendmail;

# We want to test how we build the arguments for our pipe to sendmail on both
# Win32 and everything else, no matter which of those we're running on, so we
# subclass to lie about the platform.
{
  package Test::Sendmail::Win32;
  use Moo;
  extends 'Email::Sender::Transport::Sendmail';
  sub _is_win32 { 1 }
  no Moo;
}

{
  package Test::Sendmail::Unix;
  use Moo;
  extends 'Email::Sender::Transport::Sendmail';
  sub _is_win32 { 0 }
  no Moo;
}

my $WIN32_PROG = 'C:\\Program Files\\sendmail\\sendmail.exe';
my $UNIX_PROG  = '/usr/sbin/sendmail';

sub win32_args_ok {
  my ($desc, $envelope, $expect) = @_;

  my $transport = Test::Sendmail::Win32->new({ sendmail => $WIN32_PROG });
  my @got = eval { $transport->_pipe_args($envelope) };
  is_deeply(\@got, $expect, "win32: $desc") or diag "error was: $@";
}

sub unix_args_ok {
  my ($desc, $envelope, $expect) = @_;

  my $transport = Test::Sendmail::Unix->new({ sendmail => $UNIX_PROG });
  my @got = eval { $transport->_pipe_args($envelope) };
  is_deeply(\@got, $expect, "unix: $desc") or diag "error was: $@";
}

sub win32_args_refused {
  my ($desc, $envelope, $expect_re) = @_;

  my $transport = Test::Sendmail::Win32->new({ sendmail => $WIN32_PROG });
  my @got = eval { $transport->_pipe_args($envelope) };
  my $error = $@;

  ok(! @got, "win32: $desc: built no command line");
  ok(
    eval { $error->isa('Email::Sender::Failure::Permanent') },
    "win32: $desc: threw a permanent failure",
  ) or diag "error was: $error";
  like($error->message, $expect_re, "win32: $desc: error names the address");
}

my $ORDINARY = {
  from => 'devnull@example.biz',
  to   => [ 'devnull@example.com', 'devnull@example.net' ],
};

win32_args_ok(
  'ordinary addresses',
  $ORDINARY,
  [ qq{| "$WIN32_PROG" -i -f devnull\@example.biz devnull\@example.com devnull\@example.net} ],
);

unix_args_ok(
  'ordinary addresses',
  $ORDINARY,
  [
    '|-', $UNIX_PROG, '-i', '-f', 'devnull@example.biz', '--',
    'devnull@example.com', 'devnull@example.net',
  ],
);

# Every one of these is a perfectly legal RFC 5322 address, but would cause
# wonky things to happen in the win32 command parser.
my %EVIL = (
  'ampersand'      => 'x&calc.exe&y@example.com',
  'pipe'           => 'x|calc.exe@example.com',
  'redirect'       => 'x>evil@example.com',
  'caret'          => 'x^y@example.com',
  'percent'        => 'x%y@example.com',
  'backtick'       => 'x`y@example.com',
  'quote'          => 'x"y@example.com',
  'space'          => '"x y"@example.com',
  'leading hyphen' => '-Cevil.cf@example.com',
  'newline'        => "x\@example.com\ncalc.exe",
);

for my $name (sort keys %EVIL) {
  my $addr = $EVIL{$name};

  win32_args_refused(
    "$name in a recipient",
    { from => 'devnull@example.biz', to => [ 'good@example.com', $addr ] },
    qr/\Q$addr\E/,
  );

  win32_args_refused(
    "$name in the sender",
    { from => $addr, to => [ 'good@example.com' ] },
    qr/\Q$addr\E/,
  );

  unix_args_ok(
    "$name passed along as an argument",
    { from => $addr, to => [ $addr ] },
    [ '|-', $UNIX_PROG, '-i', '-f', $addr, '--', $addr ],
  );
}

win32_args_refused(
  'undefined sender',
  { from => undef, to => [ 'good@example.com' ] },
  qr/\(undef\)/,
);

win32_args_refused(
  'empty sender',
  { from => q{}, to => [ 'good@example.com' ] },
  qr/""/,
);

done_testing;
