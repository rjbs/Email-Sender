#!perl
use strict;
use warnings;
use Test::More tests => 5;

use Email::Sender::Failure;

{
  my $fail = Email::Sender::Failure->new("message");
  isa_ok($fail, 'Email::Sender::Failure');
  is($fail->message, 'message', 'string alone -> message');
}

{
  eval { my $fail = Email::Sender::Failure->new(undef); };
  like($@, qr/message.{2,5}is required/, '->new(undef) -> fail');
}

{
  eval { my $fail = Email::Sender::Failure->new(''); };
  like($@, qr/must be a hash ref/i, '->new("") -> fail');
}

{
  eval { my $fail = Email::Sender::Failure->new(message => ''); };
  like($@, qr/message/i, '->new(message=>"") -> fail');
}
