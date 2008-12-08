package Email::Sender::Transport::Test;
use Mouse;
extends 'Email::Sender::Transport';

use Email::Sender::Failure::Multi;
use Email::Sender::Success::Partial;

has allow_partial_success => (is => 'ro', isa => 'Bool', default => 0);

sub recipient_failure { }
sub delivery_failure  { }

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
  my ($self, $email, $envelope) = @_;

  my @failures;
  my @ok_rcpts;

  if (my $failure = $self->delivery_failure($email, $envelope)) {
    $failure->throw;
  }

  for my $to (@{ $envelope->{to} }) {
    if (my $failure = $self->recipient_failure($to)) {
      push @failures, $failure;
    } else {
      push @ok_rcpts, $to;
    }
  }

  if (
    @failures
    and ((@ok_rcpts == 0) or (! $self->allow_partial_success))
  ) {
    $failures[0]->throw if @failures == 1 and @ok_rcpts == 0;

    my $message = sprintf '%s recipients were rejected',
      @ok_rcpts ? 'some' : 'all';

    Email::Sender::Failure::Multi->throw(
      message  => $message,
      failures => \@failures,
    );
  }

  $self->{deliveries} ||= [];
  push @{ $self->{deliveries} }, {
    email     => $email,
    envelope  => $envelope,
    successes => \@ok_rcpts,
    failures  => \@failures,
  };

  # XXX: We must report partial success (failures) if applicable.
  return $self->success unless @failures;
  return Email::Sender::Success::Partial->new({
    failure => Email::Sender::Failure::Multi->new({
      message  => 'some recipients were rejected',
      failures => \@failures
    }),
  });
}

no Mouse;
1;
