package Email::Sender::Simple;
use strict;
use warnings;

=head1 NAME

Email::Sender::Simple - the simple interface for sending mail with Sender

=cut

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => { sendmail => Sub::Exporter::Util::curry_class('send') },
};

use Email::Address;
use Email::Sender::Transport;

{
  my $DEFAULT_TRANSPORT;
  my $DEFAULT_FROM_ENV;

  sub _default_was_from_env {
    my ($self) = @_;
    $self->_default_transport;
    return $DEFAULT_FROM_ENV;
  }

  sub _default_transport {
    return $DEFAULT_TRANSPORT if $DEFAULT_TRANSPORT;
    
    if ($ENV{EMAIL_SENDER_TRANSPORT}) {
      my $transport_class = $ENV{EMAIL_SENDER_TRANSPORT};

      if ($transport_class !~ tr/://) {
        $transport_class = "Email::Sender::Transport::$transport_class";
      }

      eval "require $transport_class" or die $@;

      my %arg;
      for my $key (grep { /^EMAIL_SENDER_TRANSPORT_\w+/ } keys %ENV) {
        (my $new_key = $key) =~ s/^EMAIL_SENDER_TRANSPORT_//;
        $arg{$new_key} = $ENV{$key};
      }

      $DEFAULT_FROM_ENV  = 1;
      $DEFAULT_TRANSPORT = $transport_class->new(\%arg);
    } else {
      require Email::Sender::Transport::SMTP;
      $DEFAULT_FROM_ENV  = 0;
      $DEFAULT_TRANSPORT = Email::Sender::Transport::SMTP->new;
    }

    return $DEFAULT_TRANSPORT;
  }

  sub reset_default_transport {
    undef $DEFAULT_TRANSPORT;
    undef $DEFAULT_FROM_ENV;
  }
}

sub send {
  my ($self, $email, $arg) = @_;
  $email = Email::Sender::Transport->prepare_email($email);

  my $transport = $self->_default_transport;

  if ($arg->{transport}) {
    $arg = { %$arg }; # So we can delete mailer without ill effects.
    $transport = delete $arg->{transport} unless $self->_default_was_from_env;
  }

  my $to = $arg->{to};
  unless ($to) {
    my @to_addrs =
      map  { $_->address               }
      grep { defined                   }
      map  { Email::Address->parse($_) }
      map  { $email->get_header($_)        }
      qw(to cc);
    $to = \@to_addrs;
  }

  my $from = $arg->{from};
  unless (defined $from) {
    ($from) =
      map  { $_->address               }
      grep { defined                   }
      map  { Email::Address->parse($_) }
      map  { $email->get_header($_)        }
      qw(from);
  }

  $transport->send(
    $email,
    {
      to   => $to,
      from => $from,
    },
  );

  return 1;
}

"220 OK";
