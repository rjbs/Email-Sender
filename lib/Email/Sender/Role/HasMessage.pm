package Email::Sender::Role::HasMessage;
use Moose::Role;
# ABSTRACT: an object that has a message

=attr message

This attribute is a message associated with the object.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

no Moose::Role;
1;
