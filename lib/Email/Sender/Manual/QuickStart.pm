use strict;
use warnings;
package Email::Sender::Manual::QuickStart;
# ABSTRACT: how to start using Email::Sender right now

=head1 QUICK START

=head2 Let's Send Some Mail!

No messing around, let's just send some mail.

  use strict;
  use Email::Sender::Simple qw(sendmail);
  use Email::Simple;
  use Email::Simple::Creator;

  my $email = Email::Simple->create(
    header => [
      To      => '"Xavier Q. Ample" <x.ample@example.com>',
      From    => '"Bob Fishman" <orz@example.mil>',
      Subject => "don't forget to *enjoy the sauce*",
    ],
    body => "This message is short, but at least it's cheap.\n",
  );

  sendmail($email);

That's it.  Your message goes out into the internet and tries to get delivered
to C<x.ample@example.com>.

In the example above, C<$email> could be an Email::Simple object, a
MIME::Entity, a string containing an email message, or one of several other
types of input.  If C<Email::Abstract> can understand a value, it can be passed
to Email::Sender::Simple.  Email::Sender::Simple tries to make a good guess
about how to send the message.  It will usually try to use the F<sendmail>
program on unix-like systems and to use SMTP on Windows.  You can specify a
transport, if you need to, but normally that shouldn't be an issue.  (See
L</Picking a Transport>, though, for more information.)

Also note that we imported and used a C<sendmail> routine in the example above.
This is exactly the same as saying:

  Email::Sender::Simple->send($email);

...but it's a lot easier to type.  You can use either one.

=head3 envelope information

We didn't have to tell Email::Sender::Simple where to send the message.  If you
don't specify recipients, it will use all the email addresses it can find in
the F<To> and F<Cc> headers by default.  It will use L<Email::Address> to parse
those fields.  Similarly, if no sender is specified, it will use the first
address found in the F<From> header.

In most email transmission systems, though, the headers are not by necessity
tied to the addresses used as the sender and recipients.  For example, your
message header might say "From: mailing-list@example.com" while your SMTP
client says "MAIL FROM:E<lt>verp-1234@lists.example.comE<gt>".  This is a
powerful feature, and is necessary for many email application.  Being able to
set those distinctly is important, and Email::Sender::Simple lets you do this:

  sendmail($email, { to => [ $to_1, $to_2 ], from => $sender });

=head3 in case of error

When the message is sent successfully (at least on to its next hop),
C<sendmail> will return a true value -- specifically, an
L<Email::Sender::Success> object.  This object only rarely has much use.
What's more useful is what happens if the message can't be sent.

If there is an error sending the message, an exception will be thrown.  It will
be an object belonging to the class L<Email::Sender::Failure>.  This object
will have a C<message> attribute describing the nature of the failure.  There
are several specialized forms of failure, like
L<Email::Sender::Failure::Multi>, which is thrown when more than one error is
encountered when trying to send.  You don't need to know about these to use
Email::Sender::Simple, though.  All you need to know is that C<sendmail>
returns true on success and dies on failure.

If you'd rather not have to catch exceptions for failure to send mail, you can
use the C<try_to_send> method, which can be imported as C<try_to_sendmail>.
This method will return just false on failure to send mail.

For example:

  Email::Sender::Simple->try_to_send($email, { ... });

  use Email::Sender::Simple qw(try_to_sendmail);
  try_to_sendmail($email, { ... });

Some Email::Sender transports can signal success if some, but not all,
recipients could be reached.  Email::Sender::Simple does its best to ensure
that this never happens.  When you are using Email::Sender::Simple, mail should
either be sent or not.  Partial success should never occur.

=head2 Picking a Transport

=head3 passing in your own transport

If Email::Sender::Simple doesn't pick the transport you want, or if you have
more specific needs, you can specify a transport in several ways.  The simplest
is to build a transport object and pass it in.  You can read more about
transports elsewhere.  For now, we'll just assume that you need to send mail
via SMTP on an unusual port.  You can send mail like this:

  my $transport = Email::Sender::Transport::SMTP->new({
    host => 'smtp.example.com',
    port => 2525,
  });

  sendmail($email, { transport => $transport });

Now, instead of guessing at what transport to use, Email::Sender::Simple will
use the one you provided.  This transport will have to be specified for each
call to C<sendmail>, so you might want to look at other options, which follow.

=head3 specifying transport in the environment

If you have a program that makes several calls to Email::Sender::Simple, and
you need to run this program using a different mailserver, you can set
environment variables to change the default.  For example:

  $ export EMAIL_SENDER_TRANSPORT=SMTP
  $ export EMAIL_SENDER_TRANSPORT_host=smtp.example.com
  $ export EMAIL_SENDER_TRANSPORT_port=2525

  $ perl your-program

It is important to note that if you have set the default transport by using the
environment, I<< no subsequent C<transport> args to C<sendmail> will be
respected >>.  If you set the default transport via the environment, that's it.
Everything will use that transport.  (Also, note that while we gave the host and
port arguments above in lower case, the casing of arguments in the environment
is flattened to support systems where environment variables are of a fixed
case.  So, C<EMAIL_SENDER_TRANSPORT_PORT> would also work.

This is extremely valuable behavior, as it allows you to audit every message
that would be sent by a program by running something like this:

  $ export EMAIL_SENDER_TRANSPORT=Maildir
  $ perl your-program

In that example, any message sent via Email::Sender::Simple would be delivered
to a maildir in the current directory.

=head3 subclassing to change the default transport

If you want to use a library that will behave like Email::Sender::Simple but
with a different default transport, you can subclass Email::Sender::Simple and
replace the C<build_default_transport> method.

=head2 Testing

Email::Sender::Simple makes it very, very easy to test code that sends email.
The simplest way is to do something like this:

  use Test::More;
  BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
  use YourCode;

  YourCode->run;

  my @deliveries = Email::Sender::Simple->default_transport->deliveries;

Now you've got an array containing every delivery performed through
Email::Sender::Simple, in order.  Because you set the transport via the
environment, no other code will be able to force a different transport.

When testing code that forks, L<Email::Sender::Transport::SQLite> can be used
to allow every child process to deliver to a single, easy to inspect
destination database.

=head1 SEE ALSO

=head2 This is awesome!  Where can I learn more?

Have a look at L<Email::Sender::Manual>, where all the manual's documents are
listed.  You can also look at the documentation for L<Email::Sender::Simple>
and the various Email::Sender::Transport classes.

=cut

1;
