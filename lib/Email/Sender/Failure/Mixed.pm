package Email::Sender::Failure::Mixed;
use Squirrel;
extends 'Email::Sender::Failure';

has 'failures' => (
  is  => 'ro',
  isa => 'ArrayRef',
);

no Squirrel;
1;
