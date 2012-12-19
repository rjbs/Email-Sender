package Email::Sender::Failure;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef);
use Carp ();
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

This returns a list of addresses to which the email could not be sent.

=cut

has recipients => (
  isa     => ArrayRef,
  default => sub {  []  },
  writer  => '_set_recipients',
  reader  => '__get_recipients',
  is      => 'rw',
  accessor => undef,
);

sub __recipients {
  my ($self) = @_;
  return @{$self->{recipients}};
}

sub recipients {
  my ($self) = @_;
  return $self->__recipients if wantarray;
  return $self->__recipients if ! defined wantarray;

  Carp::carp("recipients in scalar context is deprecated and WILL BE REMOVED");
  return $self->__get_recipients;
}

=method throw

This method can be used to instantiate and throw an Email::Sender::Failure
object at once.

  Email::Sender::Failure->throw(\%arg);

Instead of a hashref of args, you can pass a single string argument which will
be used as the C<message> of the new failure.

=cut

sub BUILD {
  my ($self) = @_;
  Carp::confess("message must contain non-space characters")
    unless $self->message =~ /\S/;
}

=head1 SEE ALSO

=over

=item * L<Email::Sender::Permanent>

=item * L<Email::Sender::Temporary>

=item * L<Email::Sender::Multi>

=back

=cut

no Moo;
1;
