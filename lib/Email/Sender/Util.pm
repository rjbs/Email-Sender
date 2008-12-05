use strict;
use warnings;
package Email::Sender::Util;

# This code will be used by Email::Sender::Simple. -- rjbs, 2008-12-04
sub recipients_from_email {
  my ($self, $email) = @_;

  my @to = map { $_->address }
           map { Email::Address->parse($_) }
           map { $email->get_header($_) }
           qw(to cc);

  return \@to;
}

sub sender_from_email {
  my ($self, $email) = @_;

  my ($sender) = map { $_->address }
                 map { Email::Address->parse($_) }
                 scalar $email->get_header('from');

  return $sender;
}

1;
