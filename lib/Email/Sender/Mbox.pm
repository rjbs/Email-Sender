use strict;
use warnings;

package Email::Sender::Mbox;
use base qw(Email::Sender);

use Carp;
use File::Path;
use File::Basename;
use Email::Simple 1.998;  # needed for ->header_obj
use Fcntl ':flock';

use vars qw($VERSION);
$VERSION = "0.001";

sub send_email {
  my ($self, $email) = @_;

  my @files = ref $self->{file} ? @{ $self->{file} } : $self->{file};

  return $self->failure("no mbox files specified") unless @files;

  my %failure;

  FILE: for my $file (@files) {
    eval {
      my $fh = $self->_open_fh($file);

      if (tell($fh) > 0) {
        print $fh "\n" or Carp::confess "couldn't write to $file: $!";
      }

      print $fh $self->_from_line($email)
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
    return $self->failure;
  } else {
    return $self->success({ failures => \%failure });
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
  my ($class, $email) = @_;

  # The qmail way.
  return $ENV{UFLINE} . $ENV{RPLINE} . $ENV{DTLINE} if exists $ENV{UFLINE};

  # The boring way.
  return $class->_from_line_boring($email);
}

sub _from_line_boring {
  my $self = shift;
  my $mail = shift;
  my $from = $mail->header("Return-path")
    || $mail->header("Sender")
    || $mail->header("Reply-To")
    || $mail->header("From")
    || 'root@localhost';

  my ($address) = Email::Address->parse($from);

  my $from_address = $address->address;

  my $fromtime = localtime;
  $fromtime =~ s/(:\d\d) \S+ (\d{4})$/$1 $2/;  # strip timezone.
  return "From $from_address  $fromtime\n";
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

1;
