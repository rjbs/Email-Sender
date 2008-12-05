package Email::Sender::Transport::SMTP;
use Squirrel;
extends 'Email::Sender::Transport';

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

has helo      => (is => 'ro', isa => 'Str');
has localaddr => (is => 'ro');
has localport => (is => 'ro', isa => 'Int');

has sasl_user     => (is => 'ro', isa => 'Str');
has sasl_password => (is => 'ro', isa => 'Str');

sub send_email {
  my ($self, $email, $env) = @_;

  my @undeliverable;
  my $hook = sub { @undeliverable = @{ $_[0] } };

  my $fail = sub { die shift };

  my $class = "Net::SMTP";
  if ($self->ssl) {
    require Net::SMTP::SSL;
    $class = "Net::SMTP::SSL";
  } else {
    require Net::SMTP;
  }

  Carp::croak("no valid emails in recipient list") unless
    my @to = grep { defined and length } @{ $env->{to} };

  my $smtp = $class->new(
    $self->host,
    Port => $self->port,
    $self->helo      ? (Hello     => $self->helo)      : (),
    $self->localaddr ? (LocalAddr => $self->localaddr) : (),
    $self->localport ? (LocalPort => $self->localport) : (),
  ) or return $fail->("unable to establish smtp connection");

  my $ERROR = sub {
    return $fail->("$_[0] " . $smtp->message);
  };

  if ($self->sasl_user) {
    $ERROR->("sasl_user but no sasl_password")
      unless defined $self->sasl_password;

    $smtp->auth($self->sasl_user, $self->sasl_password)
      or return $ERROR->("failed AUTH");
  }

  $smtp->mail(_quoteaddr($env->{from}))
    or return $ERROR->("$env->{from} failed after MAIL FROM:");

  if (my $hook = $self->bad_to_hook) {
    my @ok_recip
      = $smtp->to((map { _quoteaddr($_) } @to), { SkipBad => 1 });

    # In case NOTHING was OK.
    if (not(@ok_recip) or (@ok_recip == 1 and $ok_recip[0] eq '0')) {
      $smtp->to(map { _quoteaddr($_) } @to)
        or return $ERROR->("$env->{from} failed after RCPT TO:");
    }

    my %ok = map { $_ => 1 } @ok_recip;
    my @fail = grep { !$ok{$_} } @to;

    $hook->(\@fail);
  } else {
    $smtp->to(map { _quoteaddr($_) } @to)
      or return $ERROR->("$env->{from} failed after RCPT TO:");
  }

  # restore Pobox's support for streaming, code-based messages, and arrays here
  # -- rjbs, 2008-12-04

  eval {
    $smtp->data or die "after DATA\n";
    $smtp->datasend($email->as_string) or die "during DATA\n";
    $smtp->dataend or die "after . (end of data)\n";
  };

  if ($@) {
    chomp(my $err = $@);
    return $ERROR->("$env->{from} failed $err");
  }

  $smtp->quit;

  if (@undeliverable) {
    $self->partial_failure(
      { map { $_ => 'rejected by smtp server' } @undeliverable }
    );
  } else {
    return $self->success;
  }
}

no Squirrel;
1;
