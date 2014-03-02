package Email::Sender::Failure::Multi;
# ABSTRACT: an aggregate of multiple failures

use Moo;
extends 'Email::Sender::Failure';

use MooX::Types::MooseLike::Base qw(ArrayRef);

=head1 DESCRIPTION

A multiple failure report is raised when more than one failure is encountered
when sending a single message, or when mixed states were encountered.

=attr failures

This method returns a list of other Email::Sender::Failure objects represented
by this multi.

=cut

has failures => (
  is       => 'ro',
  isa      => ArrayRef,
  required => 1,
  reader   => '__get_failures',
);

sub __failures { @{$_[0]->__get_failures} }

sub failures {
  my ($self) = @_;
  return $self->__failures if wantarray;
  return if ! defined wantarray;

  Carp::carp("failures in scalar context is deprecated and WILL BE REMOVED");
  return $self->__get_failures;
}

sub recipients {
  my ($self) = @_;
  my @rcpts = map { $_->recipients } $self->failures;

  return @rcpts if wantarray;
  return if ! defined wantarray;

  Carp::carp("recipients in scalar context is deprecated and WILL BE REMOVED");
  return \@rcpts;
}

=method isa

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

no Moo;
1;
