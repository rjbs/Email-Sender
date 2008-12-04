package Email::Sender::Wrapper;
use base qw(Email::Sender);

use warnings;
use strict;

use Carp qw(confess);
use Class::Trigger;

=head1 NAME

Email::Sender::Wrapper - a mailer that wraps a mailer for mailing mail

=head1 VERSION

version 0.001

 $Id$

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

  package Email::Send::Mailer::Backwards;
  use base qw(Email::Send::Mailer::Wrapper);

  __PACKAGE__->add_trigger(before_send => sub {
    my ($self, $message, $arg) = @_;
    $message->body_set(reverse $message->body);
  }

=head1 DESCRIPTION

=cut

sub new {
  my ($class, $arg) = @_;
  $arg ||= {};

  eval "require $arg->{mailer};" if not ref $arg->{mailer};
  confess "mailer isn't a Mailer"
    unless eval { $arg->{mailer}->isa('Email::Sender') };

  my $new_arg = {%$arg};
  delete $new_arg->{mailer};
  $arg->{mailer} = $arg->{mailer}->new($new_arg) unless ref $arg->{mailer};
  my $self = bless $arg => $class;

  return $self;
}

sub AUTOLOAD { ## no critic Autoload
  our $AUTOLOAD;
  my $self = shift;
  my ($class, $method) = $AUTOLOAD =~ /(.+)::([^:]+)$/;
  return if $method eq 'DESTROY';

  $self->{mailer}->$method(@_);
}

sub send_email {
  my $self = shift;

  my $return = eval { $self->call_trigger(before_send_email => (@_)); };

  # This is not a problem.  We're just re-throwing an exception.
  die $@         if $@; ## no critic Carp

  return $return if $return;

  $self->{mailer}->send_email(@_);
}

=head1 AUTHOR

Ricardo Signes, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-send-mailer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2006 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
