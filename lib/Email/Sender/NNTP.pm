use strict;
use warnings;

package Email::Sender::NNTP;
use base qw(Email::Sender);

use Net::NNTP;

sub nntp {
  my ($self) = @_;

  $self->{'Email::Sender::NNTP'}{nntp} ||= Net::NNTP->new(

    # get args from person
  );
}

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  $self->total_failure("failed to post")
    unless $self->nntp->post($email->as_string);

  return $self->success;
}

sub DESTROY {
  my ($self) = @_;
  $self->nntp->quit;
}

1;
