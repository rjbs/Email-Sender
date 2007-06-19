package Email::Sender;

use warnings;
use strict;

use Email::Simple;
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

  package Email::Sender::Mailer::DevNull;
  use base qw(Email::Sender::Mailer);

  sub send {
    my ($self, $message, $arg) = @_;
    return $self->success;
  }

  ...

  my $mailer = Email::Sender::Mailer::DevNull->new;
  my $sender = Email::Sender->new({ mailer => $mailer });
  $sender->send($message, { to => [ $recipient, ... ], from => $from });

=head1 DESCRIPTION

This module provides an extended API for maielrs used by Email::Sender.

=cut

# this should return the class name, croak on args, etc, for singletonian
# mailers..?
sub new {
  my ($class, $arg) = @_;
  $arg ||= {};
  return bless $arg => $class;
}

for my $method (qw(send_email)) {
  Sub::Install::install_sub({
    code => sub {
      my $class = ref $_[0] ? ref $_[0] : $_[0];
      die "virtual method $method not implemented on $class";
    },
    as => $method
  });
}

sub send {
  my ($self, $message, $arg) = @_;

  Carp::croak "invalid argument to send; first argument must be an email"
    unless my $email = $self->_objectify_message($message);

  $self->setup_envelope($email, $arg);
  $self->validate_send_args($email, $arg);

  # $self->preprocess_message($message);

  return $self->send_email($email, $arg);
}

sub validate_send_args {
  return $_[2];
}

sub setup_envelope {
  my ($self, $email, $arg) = @_;
  $arg ||= {};

  $arg->{to} = $arg->{to} ? [ $arg->{to} ] : [ ] if not ref $arg->{to};
  $arg->{to} = [ map { $email->header($_) } qw(to cc) ] if not @{ $arg->{to} };

  $arg->{from} ||= $email->header('from');
}

sub _objectify_message {
  my ($self, $message) = @_;

  return unless defined $message;

  if (Scalar::Util::blessed $message) {
    return $message if $message->isa('Email::Simple');
    return eval { Email::Abstract->cast($message => 'Email::Simple') }
      if eval { require Email::Abstract; 1; };
  } else {
    return Email::Simple->new($message);
  }

  return;
}

# send args:
#   message
#   to
#   from

sub success {
  my ($self, $arg) = @_;
  $arg ||= {};

  return bless $arg => 'Email::Sender::Success';
}

sub failure {
  my ($self, $arg) = @_;
  die;
}

{
  package Email::Sender::Success;
  sub failures { $_[0]->{failures} }
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-send-mailer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2006-2007 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
