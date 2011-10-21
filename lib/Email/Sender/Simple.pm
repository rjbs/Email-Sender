package Email::Sender::Simple;
use Any::Moose;
with 'Email::Sender::Role::CommonSending';
# ABSTRACT: the simple interface for sending mail with Sender

=head1 SEE INSTEAD

For now, the best documentation of this class is in
L<Email::Sender::Manual::QuickStart>.

=cut

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => {
    sendmail        => Sub::Exporter::Util::curry_class('send'),
    try_to_sendmail => Sub::Exporter::Util::curry_class('try_to_send'),
  },
};

use Email::Address;
use Email::Sender::Transport;
use Try::Tiny;

{
  my $DEFAULT_TRANSPORT;
  my $DEFAULT_FROM_ENV;

  sub _default_was_from_env {
    my ($self) = @_;
    $self->default_transport;
    return $DEFAULT_FROM_ENV;
  }

  sub default_transport {
    return $DEFAULT_TRANSPORT if $DEFAULT_TRANSPORT;
    my ($self) = @_;

    if ($ENV{EMAIL_SENDER_TRANSPORT}) {
      my $transport_class = $ENV{EMAIL_SENDER_TRANSPORT};

      if ($transport_class !~ tr/://) {
        $transport_class = "Email::Sender::Transport::$transport_class";
      }

      require Class::Load;
      Class::Load::load_class($transport_class);

      my %arg;
      for my $key (grep { /^EMAIL_SENDER_TRANSPORT_\w+/ } keys %ENV) {
        (my $new_key = $key) =~ s/^EMAIL_SENDER_TRANSPORT_//;
        $arg{lc $new_key} = $ENV{$key};
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
    require Email::Sender::Transport::Sendmail;
    my $transport = eval { Email::Sender::Transport::Sendmail->new };

    return $transport if $transport;

    require Email::Sender::Transport::SMTP;
    Email::Sender::Transport::SMTP->new;
  }

  sub reset_default_transport {
    undef $DEFAULT_TRANSPORT;
    undef $DEFAULT_FROM_ENV;
  }
}

# Maybe this should be an around, but I'm just not excited about figuring out
# order at the moment.  It just has to work. -- rjbs, 2009-06-05
around prepare_envelope => sub {
  my ($orig, $self, $arg) = @_;
  $arg ||= {};
  my $env = $self->$orig($arg);

  $env = {
    %$arg,
    %$env,
  };

  return $env;
};

sub send_email {
  my ($self, $email, $arg) = @_;

  my $transport = $self->default_transport;

  if ($arg->{transport}) {
    $arg = { %$arg }; # So we can delete transport without ill effects.
    $transport = delete $arg->{transport} unless $self->_default_was_from_env;
  }

  confess("transport $transport not safe for use with Email::Sender::Simple")
    unless $transport->is_simple;

  my ($to, $from) = $self->_get_to_from($email, $arg);

  Email::Sender::Failure::Permanent->throw("no recipients") if ! @$to;
  Email::Sender::Failure::Permanent->throw("no sender") if ! defined $from;

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

  try {
    return $self->send($email, $arg);
  } catch {
    my $error = $_ || 'unknown error';
    return if try { $error->isa('Email::Sender::Failure') };
    die $error;
  };
}

sub _get_to_from {
  my ($self, $email, $arg) = @_;

  my $to = $arg->{to};
  unless (@$to) {
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

no Any::Moose;
"220 OK";
