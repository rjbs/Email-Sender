package Email::Sender::Test;
use base qw(Email::Sender);

use strict;
use warnings;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(qw(bad_recipients));

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
  my ($self, $email, $arg) = @_;

  my @failures;
  my @deliverables;

  for my $to (@{ $arg->{to} }) {
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

  $self->total_failure(\@failures) if @deliverables == 0;

  $self->_deliver(
    {
      email     => $email,
      arg       => $arg,
      successes => \@deliverables,
      failures  => \@failures,
    }
  );

  if (@failures) {
    $self->partial_failure(\@failures);
  } else {
    return $self->success;
  }
}

1;
