package Test::Email::SMTPRig;
use Mouse;

has 'smtp_host' => (is => 'ro', required => 1);
has 'smtp_ssl'  => (is => 'ro', default  => 0);

has 'smtp_port' => (
  is  => 'ro',
  isa => 'Int',
  lazy    => 1,
  default => sub { return $_[0]->ssl ? 465 : 25; },
);

has '_client_id' => (is => 'rw', init_arg => undef);

sub client_id { $_[0]->_client_id }

before register_client => sub {
  my ($self) = @_;
  if (my $id = $self->client_id) {
    Carp::confess("can't register client, already registered with id <$id>")
  }
};

sub register_client {
  my ($self) = @_;
  $self->_client_id(sprintf('smtprig-%s-%s.%s', $^T, $$, $self->smtp_host));
  return $self->_client_id;
}

sub prep_next_transaction { }

# sub get_deliveries

sub BUILD {
  my ($self) = @_;
  $self->register_client;
}

no Mouse;
1;
