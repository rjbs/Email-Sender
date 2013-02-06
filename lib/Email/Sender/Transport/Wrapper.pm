package Email::Sender::Transport::Wrapper;
use Moo;
with 'Email::Sender::Transport';
# ABSTRACT: a mailer to wrap a mailer for mailing mail

=head1 DESCRIPTION

Email::Sender::Transport::Wrapper wraps a transport, provided as the
C<transport> argument to the constructor.  It is provided as a simple way to
use method modifiers to create wrapping classes.

=cut

has transport => (
  is   => 'ro',
  does => 'Email::Sender::Transport',
  required => 1,
);

sub send_email {
  my $self = shift;

  $self->transport->send_email(@_);
}

sub is_simple {
  return $_[0]->transport->is_simple;
}

sub allow_partial_success {
  return $_[0]->transport->allow_partial_success;
}

no Moo;
1;
