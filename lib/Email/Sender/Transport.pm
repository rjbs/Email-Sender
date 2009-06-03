package Email::Sender::Transport;
use Moose::Role;

=head1 NAME

Email::Sender::Transport - role for email transports

=cut

with 'Email::Sender::Role::CommonSending';

sub is_simple {
  my ($self) = @_;
  return if $self->allow_partial_success;
  return 1;
}

=head2 allow_partial_success

If true, the transport may signal partial success by returning an
L<Email::Sender::Success::Partial> object.  For most transports, this is always
false.

=cut

sub allow_partial_success { 0 }

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

no Moose::Role;
1;
