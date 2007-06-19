use strict;

package Email::Sender::Sendmail;
use base qw(Email::Sender);

use File::Spec ();
use Return::Value;
use Symbol qw(gensym);

use vars qw($SENDMAIL);

sub _find_sendmail {
  my $self = shift;

  return $self->{sendmail}
    if $self->{sendmail} and $self->{sendmail} =~ m{[\\/]};

  my $program_name = defined $self->{sendmail} ? $self->{sendmail} : 'sendmail';

  for my $dir (File::Spec->path) {
    my $sendmail = File::Spec->catfile($dir, $program_name);
    return $sendmail if -x $sendmail;
  }

  die "couldn't find a sendmail executable";
}

sub send_email {
  my ($self, $email) = @_;

  my $pipe  = gensym;
  my $sendmail = $self->_find_sendmail;

  open $pipe, '|-', $sendmail or die "couldn't open pipe to sendmail: $!";

  print $pipe $email->as_string
    or die "couldn't send message to sendmail: $!";

  close $pipe or die "error when closing pipe to sendmail: $!";

  return $self->success;
}

1;
