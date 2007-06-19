use strict;

package Email::Sender::IOAll;
use base qw(Email::Sender);

use IO::All ();

sub io {
  return IO::All::io($_[0]->_dest);
}

sub _dest {
  my ($self) = @_;
  $self->{dest} || '=';
}

sub send_email {
  my ($self, $email) = @_;

  $self->io->append($email->as_string);

  return $self->success;
}

1;
