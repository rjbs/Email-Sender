package Email::Sender::Failable;
use base qw(Email::Sender::Wrapper);

use strict;
use warnings;

sub fail_if { my ($self, $cond) = @_; push @{ $self->{fail_if} }, $cond; }
sub failure_conditions { @{ $_[0]->{fail_if} ||= [] } }
sub clear_failure_conditions { @{ $_[0]->{fail_if} } = () }

__PACKAGE__->add_trigger(
  before_send_email => sub {
    my ($self, $email, $arg) = @_;

    die "failed to deliver message\n"
      if grep { $_->($self, $email, $arg) } $self->failure_conditions;
  }
);

1;
