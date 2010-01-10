package Email::Sender::Failure::Permanent;
use Moose;
extends 'Email::Sender::Failure';
# ABSTRACT: a permanent delivery failure

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Moose;
1;
