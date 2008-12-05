package Email::Sender::Transport::SMTP_X;
use Squirrel;
extends 'Email::Sender::Transport::SMTP';

use Net::SMTP;
use Sys::Hostname::Long ();

has _cached_client => (
  is => 'rw',
);

sub _smtp_client {
  my ($self) = @_;

  if (my $client = $self->_cached_client) {
    return $client if eval { $client->reset; $client->ok; };

    my $error = $@
             || 'error resetting cached SMTP connection: ' . $client->message;

    Carp::carp($error);
  }

  my $client = $self->SUPER::_smtp_client;
  $self->_cached_client($client);

  return $client;
}

no Squirrel;
1;
