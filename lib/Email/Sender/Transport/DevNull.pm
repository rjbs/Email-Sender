package Email::Sender::Transport::DevNull;
use Squirrel;
extends 'Email::Sender::Transport';

sub send_email { return $_[0]->success }

no Squirrel;
1;
