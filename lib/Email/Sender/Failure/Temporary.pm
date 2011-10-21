package Email::Sender::Failure::Temporary;
use Any::Moose;
extends 'Email::Sender::Failure';
# ABSTRACT: a temporary delivery failure

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Any::Moose;
1;
