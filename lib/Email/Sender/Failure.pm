package Email::Sender::Failure;
use Mouse;

use overload '""' => 'message', fallback => 1;

has 'message' => (
  is       => 'ro',
  required => 1,
);

sub throw {
  my $inv = shift;
  die $inv if ref $inv;
  die $inv->new(@_);
}

sub BUILDARGS {
  my ($self, @args) = @_;

  if (@args == 1 and defined $args[0] and length $args[0]) {
    return { message => $args[0] };
  }

  return $self->SUPER::BUILDARGS(@args);
}

no Mouse;
1;
