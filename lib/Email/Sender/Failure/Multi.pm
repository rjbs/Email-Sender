package Email::Sender::Failure::Multi;
use Mouse;
extends 'Email::Sender::Failure';

has failures => (
  is  => 'ro',
  isa => 'ArrayRef',
);

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

no Mouse;
1;
