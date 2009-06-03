package Email::Sender::Transport::Print;
use Moose;
with 'Email::Sender::Transport';

our $VERSION = '0.004';

=head1 NAME

Email::Sender::Transport::Print - print email to a filehandle (like stdout)

=cut

use IO::Handle;

has 'fh' => (
  is       => 'ro',
  isa      => 'IO::Handle',
  required => 1,
  default  => sub { IO::Handle->new_from_fd(fileno(STDOUT), 'w') },
);

sub send_email {
  my ($self, $email, $env) = @_;

  my $fh = $self->fh;

  $fh->printf("ENVELOPE TO  : %s\n", join(q{, }, @{ $env->{to} }) || '-');
  $fh->printf("ENVELOPE FROM: %s\n", defined $env->{from} ? $env->{from} : '-');
  $fh->print(q{-} x 10 . " begin message\n");

  $fh->print( $email->as_string );

  $fh->print(q{-} x 10 . " end message\n");

  return $self->success;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
