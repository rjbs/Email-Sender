use strict;
use warnings;
package Email::Sender::Util;
# ABSTRACT: random stuff that makes Email::Sender go

use Email::Address;
use Email::Sender::Failure;
use Email::Sender::Failure::Permanent;
use Email::Sender::Failure::Temporary;
use List::MoreUtils ();
use Module::Runtime qw(require_module);

# This code will be used by Email::Sender::Simple. -- rjbs, 2008-12-04
sub _recipients_from_email {
  my ($self, $email) = @_;

  my @to = List::MoreUtils::uniq(
           map { $_->address }
           map { Email::Address->parse($_) }
           map { $email->get_header($_) }
           qw(to cc bcc));

  return \@to;
}

sub _sender_from_email {
  my ($self, $email) = @_;

  my ($sender) = map { $_->address }
                 map { Email::Address->parse($_) }
                 scalar $email->get_header('from');

  return $sender;
}

# It's probably reasonable to make this code publicker at some point, but for
# now I don't want to deal with making a sane set of args. -- rjbs, 2008-12-09
sub _failure {
  my ($self, $error, $smtp, @rest) = @_;

  my ($code, $message);
  if ($smtp) {
    $code = $smtp->code;
    $message = $smtp->message;
    $message = "(no SMTP error message)" unless defined $message;

    $message = defined $error && length $error
             ? "$error: $message"
             : $message;
  } else {
    $message = $error;
    $message = "(no error given)" unless defined $message;
    $message = "(empty error string)" unless length $message;
  }

  my $error_class = ! $code       ? 'Email::Sender::Failure'
                  : $code =~ /^4/ ? 'Email::Sender::Failure::Temporary'
                  : $code =~ /^5/ ? 'Email::Sender::Failure::Permanent'
                  :                 'Email::Sender::Failure';

  $error_class->new({
    message => $message,
    code    => $code,
    @rest,
  });
}

sub _easy_transport {
  my ($self, $transport_class, $arg) = @_;

  if ($transport_class !~ tr/://) {
    $transport_class = "Email::Sender::Transport::$transport_class";
  }

  require_module($transport_class);
  return $transport_class->new($arg);
}

1;
