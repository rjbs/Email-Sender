package Email::Sender::Transport::Sendmail;
use Mouse;
extends 'Email::Sender::Transport';

our $VERSION = '0.002';

=head1 NAME

Email::Sender::Transport::Sendmail - send mail via sendmail(1)

=head2 DESCRIPTION

This transport sends mail by piping it to the F<sendmail> command.  If the
location of the F<sendmail> command is not provided in the constructor (see
below) then the library will look for an executable file called F<sendmail> in
the path.

To specify the location of sendmail:

  my $sender = Email::Sender::Transport::Sendmail->new({ sendmail => $path });

=cut

use File::Spec ();

has 'sendmail' => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
  lazy     => 1,
  default  => sub {
    # This should not have to be lazy, but Mouse has a bug(?) that prevents the
    # instance or partial-instance from being passed in to the default sub.
    # Laziness doesn't hurt much, though, because (ugh) of the BUILD below.
    # -- rjbs, 2008-12-04

    # return $ENV{PERL_SENDMAIL_PATH} if $ENV{PERL_SENDMAIL_PATH}; # ???
    return $_[0]->_find_sendmail('sendmail');
  },
);

sub _find_sendmail {
  my ($self, $program_name) = @_;
  $program_name ||= 'sendmail';

  for my $dir (File::Spec->path) {
    my $sendmail = File::Spec->catfile($dir, $program_name);
    return $sendmail if -x $sendmail;
  }

  Carp::confess("couldn't find a sendmail executable");
}

sub _sendmail_pipe {
  my ($self, $envelope) = @_;

  my $prog = $self->sendmail;

  my ($first, @args) = $^O eq 'MSWin32'
           ? "| $prog -f $envelope->{from} @{$envelope->{to}}"
           : (q{|-}, $prog, '-f', $envelope->{from}, @{$envelope->{to}});

  no warnings 'exec'; ## no critic
  my $pipe;
  Email::Sender::Failure->throw("couldn't open pipe to sendmail ($prog): $!")
    unless open($pipe, $first, @args);

  return $pipe;
}

sub send_email {
  my ($self, $email, $envelope) = @_;

  my $pipe = $self->_sendmail_pipe($envelope);

  print $pipe $email->as_string
    or Email::Sender::Failure->throw("couldn't send message to sendmail: $!");

  close $pipe
    or Email::Sender::Failure->throw("error when closing pipe to sendmail: $!");

  return $self->success;
}

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
