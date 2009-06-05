package Email::Sender::Role::CommonSending;
use Moose::Role;
# ABSTRACT: the common sending tasks most Email::Sender classes will need

use Carp;
use Email::Abstract;
use Email::Sender::Success;
use Email::Sender::Failure::Temporary;
use Email::Sender::Failure::Permanent;
use Scalar::Util ();

=head1 DESCRIPTION

Email::Sender::Role::CommonSending provides a number of features that should
ease writing new classes that perform the L<Email::Sender> role.  Instead of
writing a C<send> method, implementors will need to write a smaller
C<send_email> method, which will be passed an L<Email::Abstract> object and
envelope containing C<from> and C<to> entries.  The C<to> entry will be
guaranteed to be an array reference.

A C<success> method will also be provided as a shortcut for calling:

  Email::Sender::Success->new(...);

A few other minor details are handled by CommonSending; for more information,
consult the source.

The methods documented here may be overriden to alter the behavior of the
CommonSending role.

=cut

with 'Email::Sender';

requires 'send_email';

sub send {
  my ($self, $message, $env, @rest) = @_;
  my $email    = $self->prepare_email($message);
  my $envelope = $self->prepare_envelope($env);

  my $return = eval {
    $self->send_email($email, $envelope, @rest);
  };

  my $err = $@;
  return $return if $return;

  if (eval { $err->isa('Email::Sender::Failure') } and ! $err->recipients) {
    $err->_recipients([ @{ $envelope->{to} } ]);
  }

  defined($err) ? die($err) : confess('unknown error');
}

=method prepare_email

This method is passed a scalar and is expected to return an Email::Abstract
object.  You probably shouldn't override it in most cases.

=cut

sub prepare_email {
  my ($self, $msg) = @_;

  confess("no email passed in to sender") unless defined $msg;

  # We check blessed because if someone would pass in a large message, in some
  # perls calling isa on the string would create a package with the string as
  # the name.  If the message was (say) two megs, now you'd have a two meg hash
  # key in the stash.  Oops! -- rjbs, 2008-12-04
  return $msg if blessed $msg and eval { $msg->isa('Email::Abstract') };

  return Email::Abstract->new($msg);
}

=method prepare_envelope

This method is passed a hashref and returns a new hashref that should be used
as the envelope passed to the C<send_email> method.  This method is responsible
for ensuring that the F<to> entry is an array.

=cut

sub prepare_envelope {
  my ($self, $env) = @_;

  my %new_env;
  $new_env{to}   = ref $env->{to} ? $env->{to} : [ grep {defined} $env->{to} ];
  $new_env{from} = $env->{from};

  return \%new_env;
}

=method success

  ...
  return $self->success;

This method returns a new Email::Sender::Success object.  Arguments passed to
this method are passed along to the Success's constructor.  This is provided as
a convenience for returning success from subclasses' C<send_email> methods.

=cut

sub success {
  my $self = shift;
  my $success = Email::Sender::Success->new(@_);
}

no Moose::Role;
1;
