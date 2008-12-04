package Email::Sender::Transport::Failable;
use Squirrel;
extends 'Email::Sender::Transport::Wrapper';

sub fail_if { my ($self, $cond) = @_; push @{ $self->{fail_if} }, $cond; }
sub failure_conditions { @{ $_[0]->{fail_if} ||= [] } }
sub clear_failure_conditions { @{ $_[0]->{fail_if} } = () }

__PACKAGE__->add_trigger(
  before_send_email => sub {
    my ($self, $email, $env, $arg) = @_;

    die "failed to deliver message\n"
      if grep { $_->($self, $email, $env, $arg) } $self->failure_conditions;
  }
);

no Squirrel;
1;
