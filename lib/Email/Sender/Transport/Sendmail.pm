package Email::Sender::Transport::Sendmail;
# ABSTRACT: send mail via sendmail(1)

use Moo;
with 'Email::Sender::Transport';

use MooX::Types::MooseLike::Base qw(Str);

=head2 DESCRIPTION

This transport sends mail by piping it to the F<sendmail> command.  If the
location of the F<sendmail> command is not provided in the constructor (see
below) then the library will look for an executable file called F<sendmail> in
the path.

To specify the location of sendmail:

  my $sender = Email::Sender::Transport::Sendmail->new({ sendmail => $path });

=head2 Win32 and envelope addresses

Everywhere but Win32, the sendmail program is executed directly, with its
arguments passed as a list, so no shell ever sees the envelope addresses.  On
Win32, there is no way to do that on every perl this library supports, so the
program and its arguments are assembled into a command line instead.

Because that command line will be taken apart again by a command line parser,
this transport will refuse to send mail on Win32 unless every envelope address
is made up only of letters, digits, and the characters C<-._+=@>, beginning
with a letter or digit on each side of the C<@>.  Anything else -- including
plenty of addresses that are perfectly legal under RFC 5322 -- gets a
L<Email::Sender::Failure::Permanent> instead of a delivery.

Windows users who need to support unusual addresses should consider using the
SMTP sender instead.

=cut

use Email::Sender::Failure::Permanent;
use File::Spec ();

sub _is_win32 { $^O eq 'MSWin32' }

has 'sendmail' => (
  is  => 'ro',
  isa => Str,
  required => 1,
  lazy     => 1,
  default  => sub {
    # This should not have to be lazy, but Moose has a bug(?) that prevents the
    # instance or partial-instance from being passed in to the default sub.
    # Laziness doesn't hurt much, though, because (ugh) of the BUILD below.
    # -- rjbs, 2008-12-04

    # return $ENV{PERL_SENDMAIL_PATH} if $ENV{PERL_SENDMAIL_PATH}; # ???
    return $_[0]->_find_sendmail('sendmail');
  },
);

sub BUILD {
  $_[0]->sendmail; # force population -- rjbs, 2009-06-08
}

sub _find_sendmail {
  my ($self, $program_name) = @_;
  $program_name ||= 'sendmail';

  my @path = File::Spec->path;

  if ($program_name eq 'sendmail') {
    # for 'real' sendmail we will look in common locations -- rjbs, 2009-07-12
    push @path, (
      File::Spec->catfile('', qw(usr sbin)),
      File::Spec->catfile('', qw(usr lib)),
    );
  }

  for my $dir (@path) {
    my $sendmail = File::Spec->catfile($dir, $program_name);
    return $sendmail if $self->_is_win32 ? -f $sendmail : -x $sendmail;
  }

  Carp::confess("couldn't find a sendmail executable");
}

# Win32 has no argument vector:  whatever we want to pass to sendmail has to be
# assembled into a single command line, which is then taken apart again by the
# shell (or, if the sendmail program is a batch file, by cmd.exe, even when perl
# thinks it's avoiding the shell).  I won't guess, this stuff is beyond my
# level of expertise.  Just be strict, which is probably enough for nearly any
# address *really* in use.
my $WIN32_SAFE_ADDRESS = qr{\A[0-9a-z][-0-9a-z._+=]*\@[0-9a-z][-0-9a-z.]*\z}i;

sub _assert_win32_safe_envelope {
  my ($self, $envelope) = @_;

  my @unsafe = grep {; ! (defined($_) && $_ =~ $WIN32_SAFE_ADDRESS) }
               ($envelope->{from}, @{ $envelope->{to} });

  return unless @unsafe;

  Email::Sender::Failure::Permanent->throw(
    "can't pass these envelope addresses to sendmail on Win32: "
    . join(q{, }, map {; defined $_ ? qq{"$_"} : '(undef)' } @unsafe)
  );
}

# Given the $envelope, this returns the args to be passed to C<open> to get a
# pipe to sendmail.
sub _pipe_args {
  my ($self, $envelope) = @_;

  my $prog = $self->sendmail;

  return (q{|-}, $prog, '-i', '-f', $envelope->{from}, '--', @{$envelope->{to}})
    unless $self->_is_win32;

  $self->_assert_win32_safe_envelope($envelope);

  return qq(| "$prog" -i -f $envelope->{from} @{$envelope->{to}});
}

sub _sendmail_pipe {
  my ($self, $envelope) = @_;

  my $prog = $self->sendmail;

  my ($first, @args) = $self->_pipe_args($envelope);

  no warnings 'exec'; ## no critic
  my $pipe;
  Email::Sender::Failure->throw("couldn't open pipe to sendmail ($prog): $!")
    unless open($pipe, $first, @args);

  return $pipe;
}

sub send_email {
  my ($self, $email, $envelope) = @_;

  my $pipe = $self->_sendmail_pipe($envelope);

  my $string = $email->as_string;
  $string =~ s/\x0D\x0A/\x0A/g unless $self->_is_win32;

  print $pipe $string
    or Email::Sender::Failure->throw("couldn't send message to sendmail: $!");

  close $pipe
    or Email::Sender::Failure->throw("error when closing pipe to sendmail: $!");

  return $self->success;
}

no Moo;
1;
