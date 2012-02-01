#!perl
use strict;
use warnings;

use lib 't/lib';
use Test::Email::Sender::Util;
use File::Spec ();
use File::Temp ();

use Test::More tests => 10;

use Email::Sender::Transport::Maildir;

my $message = readfile('t/messages/simple.msg');

my $maildir   = File::Temp::tempdir(CLEANUP => 1);

my (undef, $failfile) = File::Temp::tempfile(UNLINK => 1);
my $faildir = File::Spec->catdir($failfile, 'Maildir');

my $sender = Email::Sender::Transport::Maildir->new({
  dir => $maildir,
});

for (1..2) {
  my $result = $sender->send(
    join('', @$message),
    {
      to   => [ 'rjbs@example.com' ],
      from => 'rjbs@example.biz',
    },
  );

  isa_ok($result, 'Email::Sender::Success', "delivery result");
  is(
    index($result->filename, $maildir),
    0,
    "the result filename begins with the maildir",
  );

  ok(
    -f $result->filename,
    "...and exists",
  );
}

my $new = File::Spec->catdir($maildir, 'new');

ok(-d $new, "maildir ./new directory exists now");

my @files = grep { $_ !~ /^\./ } <$new/*>;

is(@files, 2, "there are now two delivered messages in the Maildir");

my $lines = readfile($files[0]);

my $simple = Email::Simple->new(join '', @$lines);

is($simple->header('X-Email-Sender-To'), 'rjbs@example.com', 'env info in hdr');
is($simple->header('Lines'), 4, 'we counted lines correctly');

