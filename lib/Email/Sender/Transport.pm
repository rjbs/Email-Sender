package Email::Sender::Transport;
use Moose::Role;
# ABSTRACT: a role for email transports

with 'Email::Sender::Role::CommonSending';

sub is_simple {
  my ($self) = @_;
  return if $self->allow_partial_success;
  return 1;
}

=method allow_partial_success

If true, the transport may signal partial success by returning an
L<Email::Sender::Success::Partial> object.  For most transports, this is always
false.

=cut

sub allow_partial_success { 0 }

no Moose::Role;
1;
