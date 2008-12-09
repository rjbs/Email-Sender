#!perl
use strict;
use warnings;
use Test::More tests => 5;

use Email::Sender::Failure;
use Email::Sender::Failure::Permanent;
use Email::Sender::Failure::Temporary;
use Email::Sender::Failure::Multi;

my $fail = Email::Sender::Failure->new("generic");
my $perm = Email::Sender::Failure::Permanent->new("permanent");
my $temp = Email::Sender::Failure::Temporary->new("temporary");

my $multi_fail = Email::Sender::Failure::Multi->new({
  message  => 'multifail',
  failures => [ $fail ],
});

isa_ok($multi_fail, 'Email::Sender::Failure', 'multi(Failure)');
ok(! $multi_fail->isa('Nothing::Is::This'), 'isa is not catholic');

my $multi_perm = Email::Sender::Failure::Multi->new({
  message  => 'multifail',
  failures => [ $perm ],
});

isa_ok($multi_perm, 'Email::Sender::Failure::Permanent', 'multi(Failure::P)');

my $multi_temp = Email::Sender::Failure::Multi->new({
  message  => 'multifail',
  failures => [ $temp ],
});

isa_ok($multi_temp, 'Email::Sender::Failure::Temporary', 'multi(Failure::T)');

my $multi_mixed = Email::Sender::Failure::Multi->new({
  message  => 'multifail',
  failures => [ $fail, $perm, $temp ],
});

ok(! $multi_mixed->isa('Email::Sender::Failure::Temporary'), 'mixed <> temp');
