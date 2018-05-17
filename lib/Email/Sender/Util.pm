use strict;
use warnings;
package Email::Sender::Util;
# ABSTRACT: random stuff that makes Email::Sender go

use Email::Address::XS;
use Email::Sender::Failure;
use Email::Sender::Failure::Permanent;
use Email::Sender::Failure::Temporary;
use List::Util 1.45 ();
use Module::Runtime qw(require_module);

# This code will be used by Email::Sender::Simple. -- rjbs, 2008-12-04
sub _recipients_from_email {
  my ($self, $email) = @_;

  my @to = List::Util::uniq(
           map { $_->address }
           map { Email::Address::XS->parse($_) }
           map { $email->get_header($_) }
           qw(to cc bcc));

  return \@to;
}

sub _sender_from_email {
  my ($self, $email) = @_;

  my ($sender) = map { $_->address }
                 map { Email::Address::XS->parse($_) }
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
    $message = ! defined $message ? "(no SMTP error message)"
             : ! length  $message ? "(empty SMTP error message)"
             :                       $message;

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

=method easy_transport

  my $transport = Email::Sender::Util->easy_transport($class => \%arg);

This takes the name of a transport class and a set of args to new.  It returns
an Email::Sender::Transport object of that class.

C<$class> is rewritten to C<Email::Sender::Transport::$class> unless it starts
with an equals sign (C<=>) or contains a colon.  The equals sign, if present,
will be removed.

=cut

sub _rewrite_class {
  my $transport_class = $_[1];
  if ($transport_class !~ s/^=// and $transport_class !~ m{:}) {
    $transport_class = "Email::Sender::Transport::$transport_class";
  }

  return $transport_class;
}

sub easy_transport {
  my ($self, $transport_class, $arg) = @_;

  $transport_class = $self->_rewrite_class($transport_class);

  require_module($transport_class);
  return $transport_class->new($arg);
}

1;
