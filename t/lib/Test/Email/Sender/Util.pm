use strict;
use warnings;
package Test::Email::Sender::Util;
use Exporter;
BEGIN { our @ISA = qw(Exporter) }

our @EXPORT = qw(readfile);

sub readfile {
  my ($name) = @_;
  open my $msg_file, "<$name" or die "coudn't read $name: $!";
  my @lines = <$msg_file>;
  close $msg_file;
  return \@lines;
}

sub perform_stock_mockery {
  my ($self, $mock_smtp) = @_;

  for (qw(code message)) {
    $mock_smtp->set_bound($_ => \($mock_smtp->{$_}));
  }

  $mock_smtp->mock(fail => sub {
    my ($self, $code, $msg) = @_;
    $self->{code} = $code;
    $self->{message} = $msg;
    return;
  });

  $mock_smtp->mock(succ => sub {
    my ($self, $code, $msg) = @_;
    $self->{code} = $code || 200;
    $self->{message} = $msg || 'Ok';
    return 1;
  });

  $mock_smtp->mock(ok => sub {
    my $code = shift->code;
    return 0 < $code && $code < 400;
  });

  $mock_smtp->mock(reset => sub { $_[0]->succ });

  $mock_smtp->mock(auth => sub {
    my ($self, $user, $pass) = @_;

    return $self->fail(400 => 'fail') unless $self->{pass}{$user};
    return $self->succ if $self->{pass}{$user} eq $pass;
    return $self->fail(400 => 'fail');
  });

  for my $method (qw(mail to)) {
    $mock_smtp->mock($method => sub {
      my ($self, $addr) = @_;
      if (my $fail = $self->{failaddr}{$addr}) {
        return $self->fail(@$fail);
      }
      return $self->succ;
    });
  }

  $mock_smtp->{datafail} = '';
  for my $part (qw(data datasend dataend)) {
    $mock_smtp->mock($part => sub {
      return $_[0]->fail(300 => 'NFI') if $_[0]->{datafail} eq $part;
      return $_[0]->succ;
    });
  }
}

1;
