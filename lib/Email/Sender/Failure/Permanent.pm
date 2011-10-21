package Email::Sender::Failure::Permanent;
use Any::Moose;
extends 'Email::Sender::Failure';
# ABSTRACT: a permanent delivery failure

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Any::Moose;
1;
