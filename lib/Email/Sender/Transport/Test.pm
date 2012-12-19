package Email::Sender::Transport::Test;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef Bool);
# ABSTRACT: deliver mail in memory for testing

with 'Email::Sender::Transport';
use Email::Sender::Failure::Multi;
use Email::Sender::Success::Partial;

=head1 DESCRIPTION

This transport is meant for testing email deliveries in memory.  It will store
a record of any delivery made so that they can be inspected afterward.

=for Pod::Coverage recipient_failure delivery_failure

By default, the Test transport will not allow partial success and will always
succeed.  It can be made to fail predictably, however, if it is extended and
its C<recipient_failure> or C<delivery_failure> methods are overridden.  These
methods are called as follows:

  $self->delivery_failure($email, $envelope);

  $self->recipient_failure($to);

If they return true, the sending will fail.  If the transport was created with
a true C<allow_partial_success> attribute, recipient failures can cause partial
success to be returned.

For more flexible failure modes, you can override more aggressively or can use
L<Email::Sender::Transport::Failable>.

=attr deliveries

=for Pod::Coverage clear_deliveries

This attribute stores an arrayref of all the deliveries made via the transport.

Each delivery is a hashref, in the following format:

  {
    email     => $email,
    envelope  => $envelope,
    successes => \@ok_rcpts,
    failures  => \@failures,
  }

Both successful and failed deliveries are stored.

A number of methods related to this attribute are provided:

=for :list
* delivery_count
* clear_deliveries
* shift_deliveries

=cut

has allow_partial_success => (is => 'ro', isa => Bool, default => sub { 0 });

sub recipient_failure { }
sub delivery_failure  { }

has deliveries => (
  isa => ArrayRef,
  init_arg   => undef,
  default    => sub { [] },
  is         => 'ro',
  reader     => '_deliveries',
);

sub delivery_count { scalar @{ $_[0]->_deliveries } }
sub record_delivery { push @{ shift->_deliveries }, @_ }
sub deliveries { @{ $_[0]->_deliveries } }
sub shift_deliveries { shift @{ $_[0]->_deliveries } }
sub clear_deliveries { @{ $_[0]->_deliveries } = () }

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

  $self->record_delivery({
    email     => $email,
    envelope  => $envelope,
    successes => \@ok_rcpts,
    failures  => \@failures,
  });

  # XXX: We must report partial success (failures) if applicable.
  return $self->success unless @failures;
  return Email::Sender::Success::Partial->new({
    failure => Email::Sender::Failure::Multi->new({
      message  => 'some recipients were rejected',
      failures => \@failures
    }),
  });
}

no Moo;
1;
