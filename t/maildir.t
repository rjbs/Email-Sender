#!perl
use strict;
use warnings;

use File::Spec ();
use File::Temp ();

use Test::More tests => 9;

BEGIN { use_ok('Mail::LocalDelivery'); }

sub readfile {
  my ($name) = @_;
  local *MESSAGE_FILE;
  open MESSAGE_FILE, "<$name" or die "coudn't read $name: $!";
  my @lines = <MESSAGE_FILE>;
  close MESSAGE_FILE;
  return \@lines;
}

my $message = readfile('t/messages/simple.msg');

my $maildir   = File::Temp::tempdir(CLEANUP => 1);

my (undef, $failfile) = File::Temp::tempfile(UNLINK => 1);
my $faildir = File::Spec->catdir($failfile, 'Maildir');

my $sender = Email::Sender::Maildir->new(
  dir => $maildir,
);

my $result = $sender->send($message);

ok(
  (! -d File::Spec->catdir($maildir, 'new')),
  "and neither is the other temporary dir"
);

$deliver->deliver($maildir);

ok(
  (! -d File::Spec->catdir($emergency, 'new')),
  "emergency dir isn't a maildir after first accept"
);

ok(
  (  -d File::Spec->catdir($maildir, 'new')),
  "but the other maildir, which we accepted, is"
);

$deliver->deliver;

ok(
  (  -d File::Spec->catdir($emergency, 'new')),
  "after accept without dest, emergency is maildir"
);

ok(
  (! -e $mbox),
  "mbox doesn't exist before we deliver to it",
);

$deliver->deliver($mbox);

ok(
  (-e $mbox),
  "and once we deliver to it, mbox exists",
);
