package Email::Sender::STDOUT;
use base qw(Email::Sender);

use strict;
use warnings;

sub send_email {
  my ($self, $email, $arg) = @_;

  my @to = @{ $arg->{to} };

  print "ENVELOPE TO  : @to\n";
  print "ENVELOPE FROM: $arg->{from}\n";
  print q{-} x 10, " begin message\n";

  print $email->as_string;

  print q{-} x 10, " end message\n";

  return $self->success;
}

1;
