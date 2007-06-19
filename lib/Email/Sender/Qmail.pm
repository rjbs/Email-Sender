use strict;

package Email::Sender::Qmail;
use base qw(Email::Sender);

use File::Spec ();
use Return::Value;
use Symbol qw(gensym);

use vars qw[$QMAIL];
$QMAIL ||= q[qmail-inject];

sub _find_qmail {
  my $class = shift;

  my $qmail;
  for my $dir (File::Spec->path) {
    my $path = File::Spec->catfile($dir, $QMAIL);

    if (-x $path) {
      $qmail = $path;
      last;
    }
  }
  return $qmail;
}

sub send_email {
  my ($self, $email) = @_;

  my $pipe  = gensym;
  my $qmail = $self->_find_qmail;

  open $pipe, '|-', $qmail or die "couldn't open pipe to qmail: $!";

  print $pipe $email->as_string
    or die "couldn't send message to qmail: $!";

  close $pipe or die "error when closing pipe to qmail: $!";

  return $self->success;
}

1;
