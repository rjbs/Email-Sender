package Email::Sender::Role::HasMessage;
use Any::Moose 'Role';
# ABSTRACT: an object that has a message

=attr message

This attribute is a message associated with the object.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

no Any::Moose 'Role';
1;
