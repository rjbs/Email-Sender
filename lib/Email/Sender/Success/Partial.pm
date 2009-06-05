package Email::Sender::Success::Partial;
use Moose;
extends 'Email::Sender::Success';
# ABSTRACT: a report of partial success when delivering

=head1 DESCRIPTION

These objects indicate that some deliver was accepted for some recipients and
not others.  The success object's C<failure> attribute will return a
L<Email::Sender::Failure::Multi> describing which parts of the delivery failed.

=cut

use Email::Sender::Failure::Multi;

has failure => (
  is  => 'ro',
  isa => 'Email::Sender::Failure::Multi',
  required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;
