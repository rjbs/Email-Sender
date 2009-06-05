package Email::Sender::Failure::Permanent;
use Moose;
extends 'Email::Sender::Failure';
# ABSTRACT: a permanent delivery failure

__PACKAGE__->meta->make_immutable;
no Moose;
1;
