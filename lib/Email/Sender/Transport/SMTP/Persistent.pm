package Email::Sender::Transport::SMTP::Persistent;
use Moo;
extends 'Email::Sender::Transport::SMTP';
# ABSTRACT: an SMTP client that stays online

=head1 DESCRIPTION

The stock L<Email::Sender::Transport::SMTP> reconnects each time it sends a
message.  This transport only reconnects when the existing connection fails.

=cut

use Net::SMTP;

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

sub _message_complete { }

=method disconnect

  $transport->disconnect;

This method sends an SMTP QUIT command and destroys the SMTP client, if on
exists and is connected.

=cut

sub disconnect {
  my ($self) = @_;
  return unless $self->_cached_client;
  $self->_cached_client->quit;
  $self->_cached_client(undef);
}

no Moo;
1;
