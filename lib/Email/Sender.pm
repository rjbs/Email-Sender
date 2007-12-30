use warnings;
use strict;

package Email::Sender;

use Email::Base;
@Email::Sender::ISA = qw(Email::Base);

use Exception::Class (
  'Email::Exception::Sender::Failure' => {
    isa         => 'Email::Exception',
    fields      => [ qw(failures) ],
    description => "error while sending email",
  },
  'Email::Exception::Sender::PartialFailure' => {
    isa         => 'Email::Exception::Sender::Failure',
    description => "could not send to all destinations",
  },
  'Email::Exception::Sender::TotalFailure' => {
    isa         => 'Email::Exception::Sender::Failure',
    description => "could not send to any destinations",
  },
);

use Carp;
use Email::Abstract;
use Email::Address;
use Scalar::Util ();
use Sub::Install;

=head1 NAME

Email::Sender - it sends mail

=head1 VERSION

version 0.001

 $Id$

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

  package Email::Sender::STDOUT;
  use base qw(Email::Sender);

  sub send {
    my ($self, $email, $arg) = @_;
    print $email->as_string;
    return $self->success;
  }

  ...

  my $sender = Email::Sender::STDOUT->new;
  $sender->send($email, { to => [ $recipient, ... ], from => $from });

=head1 DESCRIPTION

This module provides an extended API for mailers used by Email::Sender.

=head1 METHODS

=head1 new

=cut

# this should return the class name, croak on args, etc, for singletonian
# mailers..?
sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  return bless $arg => $class;
}

=head2 send

=cut

sub send { ## no critic Homo
  my ($self, $message, $arg) = @_;

  Carp::croak "invalid argument to send; first argument must be an email"
    unless my $email = $self->_make_email_abstract($message);

  my ($envelope, $send_arg) = $self->_setup_envelope($email, $arg);
  $self->validate_send_args($email, $send_arg);

  return $self->send_email($email, $envelope, $send_arg);
}

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

=head2 validate_send_args

=cut

sub validate_send_args { }

=head2 send_email

=cut

BEGIN {
  for my $method (qw(send_email)) {
    Sub::Install::install_sub({
      code => sub {
        my $class = ref $_[0] ? ref $_[0] : $_[0];
        Carp::croak "virtual method $method not implemented on $class";
      },
      as => $method
    });
  }
}

sub _make_email_abstract {
  my ($self, $email) = @_;

  return unless defined $email;

  return $email if ref $email and eval { $email->isa('Email::Abstract') };

  return Email::Abstract->new($email);
}

# send args:
#   email
#   envelope
#   other

sub success {
  1;
}

sub partial_failure {
  my ($self, $failures) = @_;

  $self->throw(-Sender::PartialFailure => { failures => $failures });
}

sub total_failure {
  my ($self, $failures) = @_;
  
  $self->throw(-Sender::TotalFailure => { failures => $failures });
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

1;
