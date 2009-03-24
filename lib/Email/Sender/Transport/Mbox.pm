package Email::Sender::Transport::Mbox;
use Moose;
extends 'Email::Sender::Transport';

our $VERSION = '0.004';

=head1 NAME

Email::Sender::Transport::Mbox - deliver mail to an mbox on disk

=cut

use Carp;
use File::Path;
use File::Basename;
use IO::File;
use Email::Simple 1.998;  # needed for ->header_obj
use Fcntl ':flock';

=head1 DESCRIPTION

This transport delivers into an mbox.  The mbox file may be given by the 
F<filename> argument to the constructor, and defaults to F<mbox>.

The transport I<currently> assumes that the mbox is in F<mboxo> format, but
this may change or be configurable in the future.

=cut

has 'filename' => (is => 'ro', default => 'mbox', required => 1);

sub send_email {
  my ($self, $email, $env) = @_;

  my $filename = $self->filename;
  my $fh       = $self->_open_fh($filename);

  my $ok = eval {
    if ($fh->tell > 0) {
      $fh->print("\n") or Carp::confess("couldn't write to $filename: $!");
    }

    $fh->print($self->_from_line($email, $env))
      or Carp::confess("couldn't write to $filename: $!");

    $fh->print($self->_escape_from_body($email))
      or Carp::confess("couldn't write to $filename: $!");

    # This will make streaming a bit more annoying. -- rjbs, 2007-05-25
    $fh->print("\n")
      or Carp::confess("couldn't write to $filename: $!")
      unless $email->as_string =~ /\n$/;

    $self->_close_fh($fh)
      or Carp::confess "couldn't close file $filename: $!";

     1;
  };

  die unless $ok;
  # Email::Sender::Failure->throw($@ || 'unknown error') unless $ok;

  return $self->success;
}

sub _open_fh {
  my ($class, $file) = @_;
  my $dir = dirname($file);
  Carp::confess "couldn't make path $dir: $!" if not -d $dir or mkpath($dir);

  my $fh = IO::File->new($file, '>>')
    or Carp::confess "couldn't open $file for appending: $!";

  $class->_getlock($fh, $file);

  $fh->seek(0, 2);
  return $fh;
}

sub _close_fh {
  my ($class, $fh, $file) = @_;
  $class->_unlock($fh);
  return $fh->close;
}

sub _escape_from_body {
  my ($class, $email) = @_;

  my $body = $email->get_body;
  $body =~ s/^(From )/>$1/gm;

  my $simple = $email->cast('Email::Simple');
  return $simple->header_obj->as_string . $simple->crlf . $body;
}

sub _from_line {
  my ($class, $email, $envelope) = @_;

  my $fromtime = localtime;
  $fromtime =~ s/(:\d\d) \S+ (\d{4})$/$1 $2/;  # strip timezone.
  return "From $envelope->{from}  $fromtime\n";
}

sub _getlock {
  my ($class, $fh, $fn) = @_;
  for (1 .. 10) {
    return 1 if flock($fh, LOCK_EX | LOCK_NB);
    sleep $_;
  }
  Carp::confess "couldn't lock file $fn";
}

sub _unlock {
  my ($class, $fh) = @_;
  flock($fh, LOCK_UN);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
