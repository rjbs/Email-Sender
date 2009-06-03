package Email::Sender::Simple;
use Moose;
with 'Email::Sender';

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
    my ($self) = @_;
    
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
      $DEFAULT_FROM_ENV  = 0;
      $DEFAULT_TRANSPORT = $self->build_default_transport;
    }

    return $DEFAULT_TRANSPORT;
  }

  sub build_default_transport {
    require Email::Sender::Transport::SMTP;
    Email::Sender::Transport::SMTP->new;
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

  confess("transport $transport not safe for use with Email::Sender::Simple")
    unless $transport->is_simple;

  my ($to, $from) = $self->_get_to_from($email, $arg);

  return $transport->send(
    $email,
    {
      to   => $to,
      from => $from,
    },
  );
}

sub try_to_send {
  my ($self, $email, $arg) = @_;

  my $succ = eval { $self->send($email, $arg); };

  return $succ if $succ;
  my $error = $@ || 'unknown error';
  return if eval { $error->isa('Email::Sender::Failure') };

  die $error;
}

sub _get_to_from {
  my ($self, $email, $arg) = @_;

  my $to = $arg->{to};
  unless ($to) {
    my @to_addrs =
      map  { $_->address               }
      grep { defined                   }
      map  { Email::Address->parse($_) }
      map  { $email->get_header($_)    }
      qw(to cc);
    $to = \@to_addrs;
  }

  my $from = $arg->{from};
  unless (defined $from) {
    ($from) =
      map  { $_->address               }
      grep { defined                   }
      map  { Email::Address->parse($_) }
      map  { $email->get_header($_)    }
      qw(from);
  }

  return ($to, $from);
}

no Moose;
"220 OK";
