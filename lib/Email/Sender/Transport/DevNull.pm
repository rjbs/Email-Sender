package Email::Sender::Transport::DevNull;
use Moose;
with 'Email::Sender::Transport';
# ABSTRACT: happily throw away your mail

sub send_email { return $_[0]->success }

__PACKAGE__->meta->make_immutable;
no Moose;
1;
