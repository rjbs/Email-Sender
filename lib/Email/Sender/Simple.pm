package Email::Sender::Simple;
use Moose;

use Sub::Exporter::Util ();
use Sub::Exporter -setup => {
  exports => { sendmail => Sub::Exporter::Util::curry_class('send') },
};

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
        $transport_class = "Email::Send::Mailer::$transport_class";
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
      require Email::Send::Mailer::SMTP;
      $DEFAULT_FROM_ENV  = 0;
      $DEFAULT_TRANSPORT = Email::Send::Mailer::SMTP->new;
    }

    return $DEFAULT_TRANSPORT;
  }

  sub reset_default_transport {
    undef $DEFAULT_TRANSPORT;
    undef $DEFAULT_FROM_ENV;
  }
}

sub send {
  my ($self, $message, $arg) = @_;

  Carp::cluck "ICG::Sendmail->sendmail in non-void context considered harmful"
    if defined wantarray;

  my $transport = $self->_default_transport;

  if ($arg->{transport}) {
    $arg = { %$arg }; # So we can delete mailer without ill effects.
    $transport = delete $arg->{transport} unless $self->_default_was_from_env;
  }

  $transport->send_email($message, $arg);
}

no Moose;
"220 OK";
