package Email::Sender::Failure::Temporary;
use Moose;
extends 'Email::Sender::Failure';
# ABSTRACT: a temporary delivery failure

__PACKAGE__->meta->make_immutable;
no Moose;
1;
