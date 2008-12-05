package Email::Sender::Transport::SMTP;
use Squirrel;
extends 'Email::Sender::Transport';

use Params::Util ();
use Params::Validate qw(:all);
use Scalar::Util ();

# This routine sends mail via SMTP.  C<$message> is the text of the message to
# be sent.  Valid arguments are:
#
#  from - envelope sender
#  to   - envelope recipient
#  host - smtp mx to use
#  port - port on which to connect to host
#  helo - smtp helo greeting
#  ssl  - boolean: use SSL?
#  localaddr - connect from this address
#  localport - connect from this port
#  sasl_user     - use SASL, with this user
#  sasl_password - use SASL, with this password
#
#  bad_to_hook - a callback; if given, if the mail server rejects any of the
#                message recipients, this callback is called

my %valid_smtp = (
  from          => 1,
  to            => 1,
  helo          => 0,
  sasl_user     => 0,
  sasl_password => 0,
  ssl           => 0,
  localaddr     => 0,
  localport     => 0,
  bad_to_hook   => { optional => 1, type => CODEREF },
);

# these exist because of perl56 and closure leaks -- we can't generate them
# anew each smtpsend
sub _smtp_chunk_handle {
  my $fh = shift;
  return scalar <$fh>;
}

sub _smtp_chunk_code {
  my $code = shift;
  return $code->();
}

sub _smtp_chunk_array {
  return shift @{ $_[0] };
}

sub __smtp_write_datasend {
  my ($smtp, $chunk) = @_;
  $smtp->datasend($chunk) or die "during DATA\n";
}

sub _smtp_loop_stream_to {
  my ($smtp, $email) = @_;
  $email->stream_to($smtp, { write => \&__smtp_write_datasend },);
}

sub _smtp_loop_chunk {
  my ($smtp, $email, $chunker) = @_;
  while (defined(my $chunk = $chunker->($email))) {
    __smtp_write_datasend($smtp, $chunk);
  }
}

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
