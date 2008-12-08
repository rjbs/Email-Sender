package Email::Sender::Transport::SMTP;
use Mouse;
extends 'Email::Sender::Transport';

use Email::Sender::Failure::Multi;
use Email::Sender::Success::Partial;

# I am basically -sure- that this is wrong, but sending hundreds of millions of
# messages has shown that it is right enough.  I will try to make it textbook
# later. -- rjbs, 2008-12-05
sub _quoteaddr {
  my $addr       = shift;
  my @localparts = split /\@/, $addr;
  my $domain     = pop @localparts;
  my $localpart  = join q{@}, @localparts;

  # this is probably a little too paranoid
  return $addr unless $localpart =~ /[^\w.+-]/ or $localpart =~ /^\./;
  return join q{@}, qq("$localpart"), $domain;
}

has host => (is => 'ro', isa => 'Str', default => 'localhost');
has port => (
  is  => 'ro',
  isa => 'Int',
  lazy    => 1,
  default => sub { return $_[0]->ssl ? 465 : 25; },
);

has ssl => (is => 'ro');
has bad_to_hook => (is => 'ro');

has helo      => (is => 'ro', isa => 'Str'); # default to hostname_long
has localaddr => (is => 'ro');
has localport => (is => 'ro', isa => 'Int');

has sasl_user     => (is => 'ro', isa => 'Str');
has sasl_password => (is => 'ro', isa => 'Str');

has allow_partial_success => (is => 'ro', isa => 'Bool', default => 0);

sub _smtp_client {
  my ($self) = @_;

  my $class = "Net::SMTP";
  if ($self->ssl) {
    require Net::SMTP::SSL;
    $class = "Net::SMTP::SSL";
  } else {
    require Net::SMTP;
  }

  my $smtp = $class->new(
    $self->host,
    Port => $self->port,
    $self->helo      ? (Hello     => $self->helo)      : (),
    $self->localaddr ? (LocalAddr => $self->localaddr) : (),
    $self->localport ? (LocalPort => $self->localport) : (),
  );

  $self->_throw("unable to establish SMTP connection") unless $smtp;

  if ($self->sasl_user) {
    $self->_throw("sasl_user but no sasl_password")
      unless defined $self->sasl_password;

    $self->_throw('failed AUTH', $smtp)
      unless $smtp->auth($self->sasl_user, $self->sasl_password)
  }

  return $smtp;
}

sub _throw {
  my ($self, @rest) = @_;
  $self->_failure(@rest)->throw;
}

sub _failure {
  my ($self, $error, $smtp, $error_class, @rest) = @_;
  my $code = $smtp ? $smtp->code : undef;

  $error_class ||= ! $code       ? 'Email::Sender::Failure'
                 : $code =~ /^4/ ? 'Email::Sender::Failure::Temporary'
                 : $code =~ /^5/ ? 'Email::Sender::Failure::Permanent'
                 :                 'Email::Sender::Failure';

  $error_class->new({
    message => $smtp
               ? ($error ? ("$error: " . $smtp->message) : $smtp->message)
               : $error,
    code    => $code,
    @rest,
  });
}

sub send_email {
  my ($self, $email, $env) = @_;

  Carp::croak("no valid emails in recipient list") unless
    my @to = grep { defined and length } @{ $env->{to} };

  my $smtp = $self->_smtp_client;

  my $FAULT = sub { $self->_throw($_[0], $smtp); };

  $smtp->mail(_quoteaddr($env->{from}))
    or $FAULT->("$env->{from} failed after MAIL FROM:");

  my @failures;
  my @ok_rcpts;
  
  for my $addr (@to) {
    if ($smtp->to(_quoteaddr($addr))) {
      push @ok_rcpts, $addr;
    } else {
      # my ($self, $error, $smtp, $error_class, @rest) = @_;
      push @failures, $self->_failure(
        undef,
        $smtp,
        undef,
        recipients => [ $addr ],
      );
    }
  }

  # This logic used to include: or (@ok_rcpts == 1 and $ok_rcpts[0] eq '0')
  # because if called without SkipBad, $smtp->to can return 1 or 0.  This
  # should not happen because we now always pass SkipBad and do the counting
  # ourselves.  Still, I've put this comment here (a) in memory of the
  # suffering it caused to have to find that problem and (b) in case the
  # original problem is more insidious than I thought! -- rjbs, 2008-12-05

  if (
    @failures
    and ((@ok_rcpts == 0) or (! $self->allow_partial_success))
  ) {
    $failures[0]->throw if @failures == 1;

    my $message = sprintf '%s recipients were rejected during RCPT',
      @ok_rcpts ? 'some' : 'all';

    Email::Sender::Failure::Multi->throw(
      message  => $message,
      failures => \@failures,
    );
  }

  # restore Pobox's support for streaming, code-based messages, and arrays here
  # -- rjbs, 2008-12-04

  $smtp->data                        or $FAULT->("error at DATA start");
  $smtp->datasend($email->as_string) or $FAULT->("error at during DATA");
  $smtp->dataend                     or $FAULT->("error at after DATA");

  $smtp->quit;

  # XXX: We must report partial success (failures) if applicable.
  return $self->success unless @failures;
  return Email::Sender::Success::Partial->new({
    failure => Email::Sender::Failure::Multi->new({
      message  => 'some recipients were rejected during RCPT',
      failures => \@failures
    }),
  });
}

no Mouse;
1;
