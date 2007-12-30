package Email::Sender::DevNull;
use base qw(Email::Sender);

use strict;
use warnings;

sub send_email { return $_[0]->success }

1;
