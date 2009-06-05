package Email::Sender;
use Moose::Role;
# ABSTRACT: a library for sending email

requires 'send';

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

=cut

no Moose::Role;
1;
