package Email::Sender::Failure;
use Moose;
extends 'Throwable::Error';
# ABSTRACT: a report of failure from an email sending transport

=attr message

This method returns the failure message, which should describe the failure.
Failures stringify to this message.

=attr code

This returns the numeric code of the failure, if any.  This is mostly useful
for network protocol transports like SMTP.  This may be undefined.

=cut

has code => (
  is => 'ro',
);

=attr recipients

This returns a list (or, in scalar context, an arrayref) of addresses to which
the email could not be sent.

=cut

has _recipients => (
  is         => 'rw',
  isa        => 'ArrayRef',
  auto_deref => 1,
  init_arg   => 'recipients',
);

sub recipients { shift->_recipients }

=method throw

This method can be used to instantiate and throw an Email::Sender::Failure
object at once.

  Email::Sender::Failure->throw(\%arg);

Instead of a hashref of args, you can pass a single string argument which will
be used as the C<message> of the new failure.

=cut

sub BUILD {
  my ($self) = @_;
  confess("message must contain non-space characters")
    unless $self->message =~ /\S/;
}

=head1 SEE ALSO

=over

=item * L<Email::Sender::Permanent>

=item * L<Email::Sender::Temporary>

=item * L<Email::Sender::Multi>

=back

=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
no Moose;
1;
