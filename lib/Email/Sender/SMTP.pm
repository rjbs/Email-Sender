use strict;
use warnings;

package Email::Sender::SMTP;
use Email::Sender;
@Email::Sender::SMTP::ISA = qw(Email::Sender);

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

sub new {
  my ($class, $arg) = @_;

  my $smtp = $class->_new_smtp($arg);

  bless { arg => $arg, _smtp => $smtp } => $class;
}

sub send_email {
  my ($self, $email, $arg) = @_;

  eval { $self->{_smtp}->reset; };

  if ($@) {
    Carp::carp $@; # XXX should this be something else?
    $self->{_smtp} = $self->_new_smtp($self->{arg});
  }

  $arg->{smtp} = $self->{_smtp};

  $self->SUPER::send($email, $arg);
}

1;
