package Test::Email::Sender::Transport::FailEvery;
use Moo;
extends 'Email::Sender::Transport::Wrapper';

use MooX::Types::MooseLike::Base qw(Int);

has fail_every => (
  is  => 'ro',
  isa => Int,
  required => 1,
);

has current_count => (
  is  => 'rw',
  isa => Int,
  default => sub { 0 },
);

around send_email => sub {
  my ($orig, $self, $email, $env, @rest) = @_;

  my $count = $self->current_count + 1;
  $self->current_count($count);

  my $f = $self->fail_every;

  if ($count % $f == 0) {
    Email::Sender::Failure->throw("programmed to fail every $f message(s)");
  }

  return $self->$orig($email, $env, @rest);
};

no Moo;
1;
