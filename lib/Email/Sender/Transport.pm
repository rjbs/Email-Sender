package Email::Sender::Transport;
use Mouse;
# ABSTRACT: it sends mail

our $VERSION = '0.002';

use Carp;
use Email::Abstract;
use Email::Sender::Success;
use Email::Sender::Failure::Temporary;
use Email::Sender::Failure::Permanent;
use Scalar::Util ();

=head1 SYNOPSIS

  package Email::Sender::Transport::IM2000;
  use Mouse;
  extends 'Email::Sender::Transport';

  sub send_email {
    my ($self, $email, $env) = @_;
    print $email->as_string;
    return $self->success;
  }

  ...

  my $xport = Email::Sender::Transport::IM2000->new;
  $xport->send($email, { to => [ $recipient, ... ], from => $from });

=head1 DESCRIPTION

Email::Sender::Transport is the base class for mail-sending classes in the
Email::Sender system.

=head1 USER'S API

There are only three critical things to know about using an Email::Sender
transport:

=over

=item * create the transport, consulting its documentation for parameters

=item * call its send method, passing an email and envelope

=item * it will return an L<Email::Sender::Success> or throw an L<Email::Sender::Failure>

=back

Some transports will either succeed or fail totally.  Some also allow partial
success to be signalled.  Others (like LMTP) may I<require> that partial
success be accounted for.

Partial success is indicated by the return of a
L<Email::Sender::Success::Partial>.  The most commonly useful network
transports, Sendmail and SMTP, will never return a partial success in their
default configuration, so most users can avoid worrying about them.

=head2 send

  my $result = eval { $sender->send($email, \%env) };

This is the only method that most users will ever need to call.  It attempts to
send the message across the transport, and will either return success or raise
an exception.

=cut

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

  die $err;
}

=head1 DEVELOPER'S API

=head2 send_email

This method is called by C<send>, which should probably not be overriden.
Instead, override this method.  It is passed an L<Email::Abstract> object and
an envelope.  The envelope is a hashref in the following form:

  to   - an arrayref of email addresses (strings)
  from - a single email address (string)

It should either return success or throw an exception (preferably one that is
an Email::Sender::Failure).

=cut

sub send_email {
  my $class = ref $_[0] ? ref $_[0] : $_[0];
  Carp::croak "send_email method not implemented on $class";
}

=head2 prepare_email

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

=head2 prepare_envelope

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

=head2 success

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

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2006-2008, Ricardo SIGNES.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
