package Email::Sender::Failure::Multi;
use Mouse;
extends 'Email::Sender::Failure';

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
no Mouse;
1;
