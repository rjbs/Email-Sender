package Email::Sender::Failure::Multi;
use Moose;
extends 'Email::Sender::Failure';

our $VERSION = '0.003';

=head1 NAME

Email::Sender::Failure::Multi - an aggregate of multiple failures

=head1 DESCRIPTION

A multiple failure report is raised when more than one failure is encountered
when sending a single message, or when mixed states were encountered.

=head1 METHODS

=head2 failures

This method returns a list (or arrayref, in scalar context) of other
Email::Sender::Failure objects represented by this multi.

=cut

has failures => (
  is  => 'ro',
  isa => 'ArrayRef',
  auto_deref => 1,
);

sub recipients {
  my ($self) = @_;
  my @rcpts = map { $_->recipients } $self->failures;
  return wantarray ? @rcpts : \@rcpts;
}

=head2 isa

A multiple failure will report that it is a Permanent or Temporary if all of
its contained failures are failures of that type.

=cut

sub isa {
  my ($self, $class) = @_;

  if (
    $class eq 'Email::Sender::Failure::Permanent'
    or
    $class eq 'Email::Sender::Failure::Temporary'
  ) {
    my @failures = $self->failures;
    return 1 if @failures == grep { $_->isa($class) } @failures;
  }

  return $self->SUPER::isa($class);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
