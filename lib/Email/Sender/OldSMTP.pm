use strict;
use warnings;

package Email::Send::Mailer::OldSMTP;

use Email::Sender;
use Class::Accessor;

@Email::Send::Mailer::OldSMTP::ISA = qw/
  Email::Sender
  Class::Accessor
  /;

use Params::Util ();
use Params::Validate qw(:all);
use Scalar::Util ();

sub new {
  my ($class, $arg) = @_;

  bless { arg => $arg, } => $class;
}

# _smtpsend($message, %arg)

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
  host          => { default => "localhost" },
  port          => { default => 1025 },
  helo          => 0,
  sasl_user     => 0,
  sasl_password => 0,
  ssl           => 0,
  localaddr     => 0,
  localport     => 0,
  smtp          => 0,
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
  my $localpart  = join '@', @localparts;

  # this is probably a little too paranoid
  return $addr unless $localpart =~ /[^\w.+-]/ or $localpart =~ /^\./;
  return join '@', qq("$localpart"), $domain;
}

sub _smtp {
  my %arg = validate(
    @_ => {
      opt     => { type => HASHREF },
      fail    => { type => CODEREF },
      message => 0,
    },
  );
  my %o;
  if ($arg{opt}{smtp}) {
    %o = %{ $arg{opt} };
  } else {
    %o = validate_with(
      params => [ %{ $arg{opt} } ],
      spec   => \%valid_smtp,
    );
  }
  my $fail = $arg{fail};

  my $class = "Net::SMTP";
  if ($o{ssl}) {
    require Net::SMTP::SSL;
    $class = "Net::SMTP::SSL";
    if ($o{port} == 1025) {
      $o{port} = 465;
    }
  } else {
    require Net::SMTP;
  }

  $o{to} = [ $o{to} ] unless ref $o{to} eq 'ARRAY';

  $o{to} = [ grep { defined and length } @{ $o{to} } ];

  Carp::croak "no valid emails in recipient list" unless @{ $o{to} };

  my $smtp = $o{smtp} || $class->new(
    $o{host},
    Port => $o{port},
    $o{helo}      ? (Hello     => $o{helo})      : (),
    $o{localaddr} ? (LocalAddr => $o{localaddr}) : (),
    $o{localport} ? (LocalPort => $o{localport}) : (),
  ) or return $fail->("unable to establish smtp connection");

  my $ERROR = sub {
    return $fail->("$_[0] " . $smtp->message);
  };

  if ($o{sasl_user}) {
    $ERROR->("sasl_user but no sasl_password") unless $o{sasl_password};
    $smtp->auth($o{sasl_user}, $o{sasl_password})
      or return $ERROR->("$o{sasl_user} failed AUTH");
  }

  $smtp->mail(_quoteaddr($o{from}))
    or return $ERROR->("$o{from} failed after MAIL FROM:");

  if (my $hook = $o{bad_to_hook}) {
    my @ok_recip
      = $smtp->to((map { _quoteaddr($_) } @{ $o{to} }), { SkipBad => 1 },);

    # In case NOTHING was OK.
    if ((!@ok_recip) or (@ok_recip == 1 and $ok_recip[0] eq '0')) {
      $smtp->to(map { _quoteaddr($_) } @{ $o{to} })
        or return $ERROR->("$o{from} failed after RCPT TO:");
    }

    my %ok = map { $_ => 1 } @ok_recip;
    my @fail = grep { !$ok{$_} } @{ $o{to} };

    $hook->(\@fail);
  } else {
    $smtp->to(map { _quoteaddr($_) } @{ $o{to} })
      or return $ERROR->("$o{from} failed after RCPT TO:");
  }

  return $smtp unless $arg{message};

  my ($chunker, $looper);

  # XXX if we use eval { $large_string->can(...) }, perl56 explodes with ram
  # usage
  my $message_class = Scalar::Util::blessed($arg{message});

  if (Params::Util::_HANDLE($arg{message})) {
    $chunker = \&_smtp_chunk_handle;
  } elsif (Params::Util::_CODELIKE($arg{message})) {
    $chunker = \&_smtp_chunk_code;
  }

  # Email::Simple::FromHandle
  elsif ($message_class && $message_class->can('stream_to')) {
    $looper = \&_smtp_loop_stream_to;
  }

  else {
    if ($message_class && $message_class->can('as_string')) {
      $arg{message} = $arg{message}->as_string;
    }
    $arg{message} = [ $arg{message} ];
    $chunker = \&_smtp_chunk_array;
  }

  $looper = \&_smtp_loop_chunk if $chunker;

  eval {
    $smtp->data or die "after DATA\n";
    $looper->($smtp, $arg{message}, $chunker);
    $smtp->dataend or die "after . (end of data)\n";
  };
  if ($@) {
    chomp(my $err = $@);
    return $ERROR->("$o{from} failed $err");
  }

  $smtp->quit unless $o{smtp};
}

sub smtpsend {
  my $message = shift;
  _smtp(
    opt     => {@_},
    fail    => sub { die shift },
    message => $message,
  );
}

sub send_email {
  my ($self, $email, $arg) = @_;

  my @undeliverable;
  my $hook = sub { @undeliverable = @{ $_[0] } };

  _smtpsend(
    $email->as_string,
    to   => $arg->{to},
    from => $arg->{from},
    ($self->{arg}{host} ? (host => $self->{arg}{host}) : ()),
    ($self->{arg}{port} ? (port => $self->{arg}{port}) : ()),
    ($arg->{smtp}       ? (smtp => $arg->{smtp})       : ()),
    bad_to_hook => $hook,
  );

  return $self->success(
    @undeliverable
    ? {
      failures => { map { $_ => 'rejected by smtp server' } @undeliverable }
      }
    : ()
  );
}

1;
