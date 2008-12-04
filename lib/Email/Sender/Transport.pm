package Email::Sender;
use Squirrel;
# ABSTRACT: it sends mail

use Carp;
use Email::Abstract;
use Email::Address;
use Scalar::Util ();
use Sub::Install;

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

# This code belongs in Email::Sender::Simple. -- rjbs, 2008-12-04
sub _setup_envelope {
  my ($self, $email, $arg) = @_;
  $arg ||= {};

  my $envelope = {};
  my %send_arg = %$arg;
  delete $send_arg{$_} for qw(from to);

  if (defined $arg->{to} and not ref $arg->{to}) {
    $envelope->{to} = [ $arg->{to} ];
  } elsif (not defined $arg->{to}) {
    $envelope->{to} = [
      map { $_->address }
      map { Email::Address->parse($_) }
      map { $email->get_header($_) }
      qw(to cc)
    ];
  } else {
    $envelope->{to} = $arg->{to};
  }

  if ($arg->{from}) {
    $envelope->{from} = $arg->{from};
  } else {
    ($envelope->{from}) =
      map { $_->address }
      map { Email::Address->parse($_) }
      scalar $email->get_header('from');
  }

  return ($envelope, \%send_arg);
}

sub send {
  my $class = ref $_[0] ? ref $_[0] : $_[0];
  Carp::croak "send method not implemented on $class";
}

sub _make_email_abstract {
  my ($self, $email) = @_;

  return unless defined $email;

  # We check ref because if someone would pass in a large message, in some
  # perls calling isa on the string would create a package with the string as
  # the name.  If the message was (say) two megs, now you'd have a two meg hash
  # key in the stash.  Oops! -- rjbs, 2008-12-04
  return $email if ref $email and eval { $email->isa('Email::Abstract') };

  return Email::Abstract->new($email);
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

no Squirrel;
1;
