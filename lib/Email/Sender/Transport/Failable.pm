package Email::Sender::Transport::Failable;
use Mouse;
extends 'Email::Sender::Transport::Wrapper';

our $VERSION = '0.002';

=head1 NAME

Email::Sender::Transport::Failable - a wrapper to makes things fail predictably

=cut

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
no Mouse;
1;
