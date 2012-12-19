package Email::Sender::Role::HasMessage;
use Moo::Role;
# ABSTRACT: an object that has a message

=attr message

This attribute is a message associated with the object.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

no Moo::Role;
1;
