package Email::Sender::Transport::Test;
use Squirrel;
extends 'Email::Sender::Transport';

use Email::Sender::Failure::Mixed;

has 'bad_recipients' => (is => 'rw');

sub recipient_ok {
  my ($self, $recipient) = @_;

  return 1 unless my $all_exprs = $self->bad_recipients;

  for my $re (@{$all_exprs}) {
    return if $recipient =~ $re;
  }

  return 1;
}

sub _deliver {
  my ($self, $arg) = @_;
  $self->{deliveries} ||= [];

  push @{ $self->{deliveries} }, $arg;
}

sub deliveries {
  my ($self) = @_;
  return @{ $self->{deliveries} ||= [] };
}

sub delivered_emails {
  my ($self) = @_;
  map { $_->{email} } $self->deliveries;
}

sub clear_deliveries {
  delete $_[0]->{deliveries};
  return;
}

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  my @failures;
  my @deliverables;

  for my $to (@{ $envelope->{to} }) {
    if ($self->recipient_ok($to)) {
      push @deliverables, $to;
    } else {
      push @failures, {
        to    => $to,
        type  => 'permanent',
        error => 'bad recipient',
      };
    }
  }

  if (@deliverables == 0) {
    Email::Sender::Failure::Mixed->throw(failures => \@failures);
  }

  $self->_deliver(
    {
      email     => $email,
      envelope  => $envelope,
      arg       => $arg,
      successes => \@deliverables,
      failures  => \@failures,
    }
  );

  if (@failures) {
    return $self->success; # partial_failure(\@failures);
  } else {
    return $self->success;
  }
}

no Squirrel;
1;
