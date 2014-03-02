package Email::Sender::Role::HasMessage;
# ABSTRACT: an object that has a message

use Moo::Role;

=attr message

This attribute is a message associated with the object.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

no Moo::Role;
1;
