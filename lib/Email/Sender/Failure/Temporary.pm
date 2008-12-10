package Email::Sender::Failure::Temporary;
use Mouse;
extends 'Email::Sender::Failure';

=head1 NAME

Email::Sender::Failure::Permanent - a temporary delivery failure

=cut

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
