use strict;
use warnings;

package Email::Sender::Sendmail;
use base qw(Email::Sender);

use Carp qw(confess);
use File::Spec ();

use vars qw($SENDMAIL);

sub _find_sendmail {
  my $self = shift;

  $self = {} unless ref $self;

  return $self->{sendmail}
    if $self->{sendmail} and $self->{sendmail} =~ m{[\\/]};

  my $program_name = defined $self->{sendmail} ? $self->{sendmail} : 'sendmail';

  for my $dir (File::Spec->path) {
    my $sendmail = File::Spec->catfile($dir, $program_name);
    return $sendmail if -x $sendmail;
  }

  $self->throw("couldn't find a sendmail executable");
}

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  my $sendmail = $self->_find_sendmail;

  # This isn't a problem; we die if it fails, anyway. -- rjbs, 2007-07-17
  no warnings 'exec'; ## no critic
  open my $pipe, q{|-}, ($sendmail, '-f', $envelope->{from}, @{$envelope->{to}})
    or $self->throw("couldn't open pipe to sendmail: $!");

  print $pipe $email->as_string
    or $self->throw("couldn't send message to sendmail: $!");

  close $pipe
    or $self->throw("error when closing pipe to sendmail: $!");

  return $self->success;
}

1;
