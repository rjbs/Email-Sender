package Email::Sender::Success::Partial;
use Mouse;
extends 'Email::Sender::Success';

use Email::Sender::Failure::Multi;

has failure => (
  is  => 'ro',
  isa => 'Email::Sender::Failure::Multi',
  required => 1,
);

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
