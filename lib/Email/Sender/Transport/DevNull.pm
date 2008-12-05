package Email::Sender::Transport::DevNull;
use Mouse;
extends 'Email::Sender::Transport';

sub send_email { return $_[0]->success }

no Mouse;
1;
