package Email::Sender::Transport::Test;
use Mouse;
extends 'Email::Sender::Transport';

use Email::Sender::Failure::Multi;

has 'bad_recipients' => (is => 'rw');

sub recipient_ok {
  my ($self, $recipient) = @_;

  return 1 unless my $all_exprs = $self->bad_recipients;

  for my $re (@{$all_exprs}) {
    return if $recipient =~ $re;
  }

  return 1;
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
      push @failures, Email::Sender::Failure::Permanent->new({
        recipients => [ $to ],
        message    => 'bad recipient',
      });
    }
  }

  if (@deliverables == 0) {
    Email::Sender::Failure::Multi->throw(
      message  => 'could not deliver to any recipients',
      failures => \@failures,
    );
  }

  $self->{deliveries} ||= [];
  push @{ $self->{deliveries} }, {
    email     => $email,
    envelope  => $envelope,
    arg       => $arg,
    successes => \@deliverables,
    failures  => \@failures,
  };

  if (@failures) {
    return $self->success; # partial_failure(\@failures);
  } else {
    return $self->success;
  }
}

no Mouse;
1;
