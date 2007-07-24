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

sub send_email {
  my ($self, $email, $arg) = @_;

  # should use List::MoreUtils::part -- when released
  my @undeliverables = grep { not $self->recipient_ok($_) } @{ $arg->{to} };
  my @deliverables   = grep { $self->recipient_ok($_) } @{ $arg->{to} };

  # Do we want to raise an exception if there ZERO possible deliveries?
  # -- rjbs, 2007-02-20
  my $failure = { map { $_ => 'bad recipient' } @undeliverables };

  $self->_deliver(
    {
      email     => $email,
      arg       => $arg,
      successes => \@deliverables,
      failures  => $failure,
    }
  );

  if (@undeliverables) {
    $self->partial_failure($failure);
  } else {
    return $self->success;
  }
}

1;
