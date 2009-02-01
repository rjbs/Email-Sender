use warnings;
use strict;
package Email::Sender;
# ABSTRACT: it sends mail

our $VERSION = '0.001';

=head1 NAME

Email::Sender - a library for sending email

=head1 DESCRIPTION

Email::Sender replaces the old and sometimes problematic Email::Send library,
which did a decent job at handling very simple email sending tasks, but was not
suitable for serious use, for a variety of reasons.

At present, the casual user is probably best off using
L<Email::Sender::Transport::Sendmail>.  If a local F<sendmail> program is
unavailable, L<Email::Sender::Transport::SMTP> will allow you to send mail
through your relay host.

In the future, L<Email::Sender::Simple> will provide a very simple interface
for sending mail.

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
