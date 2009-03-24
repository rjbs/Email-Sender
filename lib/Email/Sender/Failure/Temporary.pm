package Email::Sender::Failure::Temporary;
use Moose;
extends 'Email::Sender::Failure';

our $VERSION = '0.003';

=head1 NAME

Email::Sender::Failure::Temporary - a temporary delivery failure

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
