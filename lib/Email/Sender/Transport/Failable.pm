package Email::Sender::Transport::Failable;
use Moose;
extends 'Email::Sender::Transport::Wrapper';
# ABSTRACT: a wrapper to makes things fail predictably

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

around send_email => sub {
  my ($orig, $self, $email, $env) = @_;

  for my $cond ($self->failure_conditions) {
    my $reason = $cond->($self, $email, $env);
    next unless $reason;
    die (ref $reason ? $reason : Email::Sender::Failure->new($reason));
  }

  return $self->$orig($email, $env);
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
