use strict;

package Email::Sender::NNTP;
use base qw(Email::Sender);

use Net::NNTP;

sub nntp {
  my ($self) = @_;

  $self->{Email::Sender::NNTP}{nntp} ||= Net::NNTP->new(
    # get args from person
  );
}

sub send_email {
  my ($self, $email, $arg) = @_;

  die "failed to post" unless $self->nntp->post($email->as_string);

  return $self->success;
}

sub DESTROY {
  $self->nntp->quit;
}

1;
