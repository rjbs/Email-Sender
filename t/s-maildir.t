#!perl
use strict;
use warnings;

use File::Spec ();
use File::Temp ();

use Test::More tests => 5;

BEGIN { use_ok('Email::Sender::Maildir'); }

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

my $sender = Email::Sender::Maildir->new({
  dir => $maildir,
});

my $result = $sender->send(
  join('', @$message),
  {
    to   => 'rjbs@example.com',
    from => 'rjbs@example.biz',
  },
);

ok($result, "successful delivery to maildir reported");

my $new = File::Spec->catdir($maildir, 'new');

ok(-d $new, "maildir/new directory exists now");

my @files = grep { $_ !~ /^\./ } <$new/*>;

is(@files, 1, "there is one delivered message in the Maildir");

my $lines = readfile($files[0]);

my $simple = Email::Simple->new(join '', @$lines);

is($simple->header('X-EmailSender-To'), 'rjbs@example.com');
