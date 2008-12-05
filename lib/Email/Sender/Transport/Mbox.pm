package Email::Sender::Transport::Mbox;
use Squirrel;
extends 'Email::Sender::Transport';

use Carp;
use File::Path;
use File::Basename;
use Email::Simple 1.998;  # needed for ->header_obj
use Fcntl ':flock';

use vars qw($VERSION);
$VERSION = "0.001";

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  my @files = ref $self->{file} ? @{ $self->{file} } : $self->{file};

  return $self->total_failure("no mbox files specified") unless @files;

  my %failure;

  FILE: for my $file (@files) {
    eval {
      my $fh = $self->_open_fh($file);

      if (tell($fh) > 0) {
        print $fh "\n" or Carp::confess "couldn't write to $file: $!";
      }

      print $fh $self->_from_line($email, $envelope)
        or Carp::confess "couldn't write to $file: $!";
      print $fh $self->_escape_from_body($email)
        or Carp::confess "couldn't write to $file: $!";

      # This will make streaming a bit more annoying. -- rjbs, 2007-05-25
      print $fh "\n"
        or Carp::confess "couldn't write to $file: $!"
        unless $email->as_string =~ /\n$/;

      $self->_close_fh($fh, $file);
    };
    $failure{$file} = $@ if $@;
  }

  if (keys %failure == @files) {
    $self->total_failure;
  } else {
    $self->partial_failure({ failures => \%failure });
  }
}

sub _open_fh {
  my ($class, $file) = @_;
  my $dir = dirname($file);
  Carp::confess "couldn't make path $dir: $!" if not -d $dir or mkpath($dir);

  open my $fh, '>>', $file
    or Carp::confess "couldn't open $file for appending: $!";
  $class->getlock($fh, $file);
  seek $fh, 0, 2;
  return $fh;
}

sub _close_fh {
  my ($class, $fh, $file) = @_;
  $class->unlock($fh);
  close $fh or Carp::confess "couldn't close file $file: $!";
  return 1;
}

sub _escape_from_body {
  my ($class, $email) = @_;

  my $body = $email->body;
  $body =~ s/^(From )/>$1/gm;

  return $email->header_obj->as_string . $email->crlf . $body;
}

sub _from_line {
  my ($class, $envelope) = @_;

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

sub unlock {
  my ($class, $fh) = @_;
  flock($fh, LOCK_UN);
}

no Squirrel;
1;
