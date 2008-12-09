package Email::Sender::Failure::Permanent;
use Mouse;
extends 'Email::Sender::Failure';

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
