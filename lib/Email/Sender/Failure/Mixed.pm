package Email::Sender::Failure::Mixed;
use Mouse;
extends 'Email::Sender::Failure';

has 'failures' => (
  is  => 'ro',
  isa => 'ArrayRef',
);

no Mouse;
1;
