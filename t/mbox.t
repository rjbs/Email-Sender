#!perl
use strict;
use warnings;

use lib 't/lib';
use Test::Email::Sender::Util;
use File::Spec ();
use File::Temp ();

use Test::More tests => 4;

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $mbox    = File::Spec->catfile($tempdir, 'mbox');

use Email::Sender::Transport::Mbox;

my $message = readfile('t/messages/simple.msg');

my $sender = Email::Sender::Transport::Mbox->new({ filename => $mbox });

for (1..2) {
  my $result = $sender->send(
    join('', @$message),
    {
      to   => [ 'rjbs@example.com' ],
      from => 'rjbs@example.biz',
    },
  );

  isa_ok($result, 'Email::Sender::Success', "delivery result");
}

ok(-f $mbox, "$mbox exists now");

open my $fh, '<', $mbox or die "couldn't open $mbox to read: $!";
my $line = <$fh>;

like( $line, qr/^From rjbs\@example\.biz/, "added a From_ line" );
