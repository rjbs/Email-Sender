package Email::Sender::Failure::Permanent;
use Moose;
extends 'Email::Sender::Failure';

our $VERSION = '0.004';

=head1 NAME

Email::Sender::Failure::Permanent - a permanent delivery failure

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
