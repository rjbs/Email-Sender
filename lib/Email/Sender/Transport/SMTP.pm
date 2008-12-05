package Email::Sender::Transport::SMTP;
use Squirrel;
extends 'Email::Sender::Transport::OldSMTP';

use Net::SMTP;
use Sys::Hostname::Long ();

sub _new_smtp {
  my ($self, $arg) = @_;
  return Net::SMTP->new(
    Host    => $arg->{host}    || 'localhost',
    Port    => $arg->{port}    || 25,
    Hello   => $arg->{helo}    || Sys::Hostname::Long::hostname_long,
    Timeout => $arg->{timeout} || 60,
  );
}

has _smtp => (
  is      => 'ro',
  default => sub { shift->_new_smtp },
);

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  eval { $self->{_smtp}->reset; };

  if ($@) {
    Carp::carp $@; # XXX should this be something else?
    $self->{_smtp} = $self->_new_smtp($self->{arg});
  }

  $arg->{smtp} = $self->{_smtp};

  $self->SUPER::send($email, $envelope, $arg);
}

no Squirrel;
1;
