package Email::Sender::DevNull;
use base qw(Email::Sender);

use strict;
use warnings;

sub send_email {
  my ($self, $email, $arg) = @_;

  return $self->success;
}

1;
