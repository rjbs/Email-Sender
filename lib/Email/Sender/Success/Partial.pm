package Email::Sender::Success::Partial;
use Mouse;
extends 'Email::Sender::Success';

has failures => (is => 'ro', isa => 'ArrayRef');

no Mouse;
1;
