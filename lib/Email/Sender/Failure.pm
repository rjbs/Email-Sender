package Email::Sender::Failure;
use Moose;

our $VERSION = '0.003';

use overload '""' => sub { $_[0]->message }, fallback => 1;

=head1 NAME

Email::Sender::Failure - a report of failure from an email sending transport

=head1 METHODS

=head2 message

This method returns the failure message, which should describe the failure.
Failures stringify to this message.

=cut

has message => (
  is       => 'ro',
  required => 1,
);

=head2 code

This returns the numeric code of the failure, if any.  This is mostly useful
for network protocol transports like SMTP.  This may be undefined.

=cut

has code => (
  is => 'ro',
);

=head2 recipients

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

sub throw {
  my $inv = shift;
  die $inv if ref $inv;
  die $inv->new(@_);
}

sub BUILD {
  my ($self) = @_;
  confess("message must contain non-space characters")
    unless $self->message =~ /\S/;
}

sub BUILDARGS {
  my ($self, @args) = @_;

  return {} unless @args;
  return {} if @args == 1 and ! defined $args[0];

  if (@args == 1 and (!ref $args[0]) and defined $args[0] and length $args[0]) {
    return { message => $args[0] };
  }

  return $self->SUPER::BUILDARGS(@args);
}

=head1 SEE ALSO

=over

=item * L<Email::Sender::Permanent>

=item * L<Email::Sender::Temporary>

=item * L<Email::Sender::Multi>

=back

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
