package Email::Sender::STDOUT;
use base qw(Email::Sender);

use strict;
use warnings;

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  my @to = @{ $envelope->{to} };

  print "ENVELOPE TO  : @to\n";
  print "ENVELOPE FROM: $envelope->{from}\n";
  print q{-} x 10, " begin message\n";

  print $email->as_string;

  print q{-} x 10, " end message\n";

  return $self->success;
}

1;
