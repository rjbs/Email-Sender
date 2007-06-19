use strict;

package Email::Sender::IOAll;
use base qw(Email::Sender);

use IO::All qw(io);

sub io {
  return io('=');
}

sub send_email {
  my ($self, $email) = @_;

  $self->io->append($email->as_string);

  return $self->success;
}

1;
