package Email::Sender::Transport::Failable;
use Squirrel;
extends 'Email::Sender::Transport::Wrapper';

has 'failure_conditions' => (
  is  => 'ro',
  isa => 'ArrayRef',
  clearer    => 'clear_failure_conditions',
  auto_deref => 1,
  default    => sub { [] },
);

sub fail_if {
  my ($self, $cond) = @_;
  push @{ scalar $self->failure_conditions }, $cond;
}

__PACKAGE__->add_trigger(
  before_send_email => sub {
    my ($self, $email, $env, $arg) = @_;

    for my $cond ($self->failure_conditions) {
      my $reason = $cond->($self, $email, $env, $arg);
      next unless $reason;
      die (ref $reason ? $reason : Email::Sender::Failure->new);
    }

    return;
  }
);

no Squirrel;
1;
