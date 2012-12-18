package Email::Sender::Success::Partial;
use Moo;
extends 'Email::Sender::Success';
use MooX::Types::MooseLike::Base qw(InstanceOf);
# ABSTRACT: a report of partial success when delivering

=head1 DESCRIPTION

These objects indicate that some deliver was accepted for some recipients and
not others.  The success object's C<failure> attribute will return a
L<Email::Sender::Failure::Multi> describing which parts of the delivery failed.

=cut

use Email::Sender::Failure::Multi;

has failure => (
  is  => 'ro',
  isa => sub { InstanceOf['Email::Sender::Failure::Multi'] },
  required => 1,
);

no Moo;
1;
