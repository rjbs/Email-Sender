package Email::Sender::Failure;
use Mouse;

use overload '""' => sub { $_[0]->message }, fallback => 1;

has message => (
  is       => 'ro',
  required => 1,
);

has _recipients => (
  is         => 'rw',
  isa        => 'ArrayRef',
  auto_deref => 1,
  init_arg   => 'recipients',
);

sub recipients { shift->_recipients }

sub throw {
  my $inv = shift;
  die $inv if ref $inv;
  die $inv->new(@_);
}

sub BUILDARGS {
  my ($self, @args) = @_;

  if (@args == 1 and (!ref $args[0]) and defined $args[0] and length $args[0]) {
    return { message => $args[0] };
  }

  return $self->SUPER::BUILDARGS(@args);
}

no Mouse;
1;
