#!perl
use strict;
use warnings;
use Test::More;

use Email::Sender::Util;

my $BASE = 'Email::Sender::Transport::';
sub with_base { "$BASE" . $_[0] }

my @rewrite = qw(  SMTP );
my @untouch = qw( =SMTP SMTP::Persistent =SMTP::Persistent );

for my $class (@rewrite) {
  is(
    Email::Sender::Util->_rewrite_class($class),
    with_base($class),
    "we do rewrite easy-transport class $class",
  );
}

for my $class (@untouch) {
  (my $no_eq = $class) =~ s/^=//;

  is(
    Email::Sender::Util->_rewrite_class($class),
    $no_eq,
    "we do NOT rewrite easy-transport class $class",
  );
}

done_testing;
