package Email::Sender::Transport::Failable;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef);
extends 'Email::Sender::Transport::Wrapper';
# ABSTRACT: a wrapper to makes things fail predictably

=head1 DESCRIPTION

This transport extends L<Email::Sender::Transport::Wrapper>, meaning that it
must be created with a C<transport> attribute of another
Email::Sender::Transport.  It will proxy all email sending to that transport,
but only after first deciding if it should fail.

It does this by calling each coderef in its C<failure_conditions> attribute,
which must be an arrayref of code references.  Each coderef will be called and
will be passed the Failable transport, the Email::Abstract object, the
envelope, and a reference to an array containing the rest of the arguments to
C<send>.

If any coderef returns a true value, the value will be used to signal failure.

=cut

has 'failure_conditions' => (
  isa => ArrayRef,
  default => sub { [] },
  is      => 'ro',
  reader  => '_failure_conditions',
);

sub failure_conditions { @{$_[0]->_failure_conditions} }
sub fail_if { push @{shift->_failure_conditions}, @_ }
sub clear_failure_conditions { @{$_[0]->{failure_conditions}} = () }

around send_email => sub {
  my ($orig, $self, $email, $env, @rest) = @_;

  for my $cond ($self->failure_conditions) {
    my $reason = $cond->($self, $email, $env, \@rest);
    next unless $reason;
    die (ref $reason ? $reason : Email::Sender::Failure->new($reason));
  }

  return $self->$orig($email, $env, @rest);
};

no Moo;
1;
