package Email::Sender::Transport::SMTP::Persistent;
use Moose;
extends 'Email::Sender::Transport::SMTP';

our $VERSION = '0.004';

=head1 NAME

Email::Sender::Transport::SMTP::Persistent - an SMTP client that stays online

=head1 DESCRIPTION

The stock Email::Sender::Transport::SMTP reconnects each time it sends a
message.  This transport only reconnects when the existing connection fails.

=cut

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

sub _message_complete { }

=head1 METHODS

=head2 disconnect

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

__PACKAGE__->meta->make_immutable;
no Moose;
1;
