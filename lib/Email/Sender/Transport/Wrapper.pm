package Email::Sender::Transport::Wrapper;
use Moo;
with 'Email::Sender::Transport';
# ABSTRACT: a mailer to wrap a mailer for mailing mail

use Email::Sender::Util;

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

sub BUILDARGS {
  my $self = shift;
  my $href = $self->SUPER::BUILDARGS(@_);

  if (my $class = delete $href->{transport_class}) {
    Carp::confess("given both a transport and transport_class")
      if $href->{transport};

    my %arg;
    for my $key (map {; /^transport_arg_(.+)$/ ? "$1" : () } keys %$href) {
      $arg{$key} = delete $href->{"transport_arg_$key"};
    }

    $href->{transport} = Email::Sender::Util->_easy_transport($class, \%arg);
  }

  return $href;
}

no Moo;
1;
