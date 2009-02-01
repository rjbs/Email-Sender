package Email::Sender::Transport::SMTP;
use Mouse;
extends 'Email::Sender::Transport';

our $VERSION = '0.002';

=head1 NAME

Email::Sender::Transport::SMTP - send email over SMTP

=cut

use Email::Sender::Failure::Multi;
use Email::Sender::Success::Partial;
use Email::Sender::Util;

=head1 DESCRIPTION

=head1 ATTRIBUTES

The following attributes may be passed to the constructor:

=over

=item host - the name of the host to connect to; defaults to localhost

=item ssl - if true, connect via SSL; defaults to false

=item port - port to connect to; defaults to 25 for non-SSL, 465 for SSL

=cut

has host => (is => 'ro', isa => 'Str',  default => 'localhost');
has ssl  => (is => 'ro', isa => 'Bool', default => 0);
has port => (
  is  => 'ro',
  isa => 'Int',
  lazy    => 1,
  default => sub { return $_[0]->ssl ? 465 : 25; },
);

=item sasl_username - the username to use for auth; optional

=item sasl_password - the password to use for auth; must be provided if username is provided

=item allow_partial_success - if true, will send data even if some recipients were rejected

=cut

has sasl_username => (is => 'ro', isa => 'Str');
has sasl_password => (is => 'ro', isa => 'Str');

has allow_partial_success => (is => 'ro', isa => 'Bool', default => 0);

=item helo - what to say when saying HELO; no default

=item localaddr - local address from which to connect

=item localpart - local port from which to connect

=back

=cut

has helo      => (is => 'ro', isa => 'Str'); # default to hostname_long
has localaddr => (is => 'ro');
has localport => (is => 'ro', isa => 'Int');

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

  if ($self->sasl_username) {
    $self->_throw("sasl_username but no sasl_password")
      unless defined $self->sasl_password;

    $self->_throw('failed AUTH', $smtp)
      unless $smtp->auth($self->sasl_username, $self->sasl_password)
  }

  return $smtp;
}

sub _throw {
  my ($self, @rest) = @_;
  Email::Sender::Util->_failure(@rest)->throw;
}

sub send_email {
  my ($self, $email, $env) = @_;

  Email::Sender::Failure->throw("no valid addresses in recipient list")
    unless my @to = grep { defined and length } @{ $env->{to} };

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
      push @failures, Email::Sender::Util->_failure(
        undef,
        $smtp,
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

  $self->_message_complete($smtp);

  # XXX: We must report partial success (failures) if applicable.
  return $self->success unless @failures;
  return Email::Sender::Success::Partial->new({
    failure => Email::Sender::Failure::Multi->new({
      message  => 'some recipients were rejected during RCPT',
      failures => \@failures
    }),
  });
}

sub _message_complete { $_[1]->quit; }

=head1 PARTIAL SUCCESS

If C<allow_partial_success> was set when creating the transport, the transport
may return L<Email::Sender::Success::Partial> objects.  Consult that module's
documentation.

=cut

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
