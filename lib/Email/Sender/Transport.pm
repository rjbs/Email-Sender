package Email::Sender::Transport;
use Mouse;
# ABSTRACT: it sends mail

use Carp;
use Email::Abstract;
use Email::Address;
use Email::Sender::Success;
use Email::Sender::Failure::Temporary;
use Email::Sender::Failure::Permanent;
use Scalar::Util ();

=head1 SYNOPSIS

  package Email::Sender::Transport::STDOUT;
  use base qw(Email::Sender::Transport);

  sub send {
    my ($self, $email, $arg) = @_;
    print $email->as_string;
    return $self->success;
  }

  ...

  my $xport = Email::Sender::Transport::STDOUT->new;
  $xport->send($email, { to => [ $recipient, ... ], from => $from });

=head1 DESCRIPTION

This module provides an extended API for mailers used by Email::Sender.

=cut

=head2 send

=cut

sub send_email {
  my $class = ref $_[0] ? ref $_[0] : $_[0];
  Carp::croak "send_email method not implemented on $class";
}

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

sub prepare_email {
  my ($self, $msg) = @_;

  return unless defined $msg;

  # We check ref because if someone would pass in a large message, in some
  # perls calling isa on the string would create a package with the string as
  # the name.  If the message was (say) two megs, now you'd have a two meg hash
  # key in the stash.  Oops! -- rjbs, 2008-12-04
  return $msg if blessed $msg and eval { $msg->isa('Email::Abstract') };

  return Email::Abstract->new($msg);
}

sub prepare_envelope {
  my ($self, $env) = @_;

  my %new_env;
  $new_env{to}   = ref $env->{to} ? $env->{to} : [ grep {defined} $env->{to} ];
  $new_env{from} = $env->{from};

  return \%new_env;
}

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

Copyright 2006-2009, Ricardo SIGNES.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
