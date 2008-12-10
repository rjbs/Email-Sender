#!perl
use strict;
use warnings;
use Test::More tests => 1;

use Email::Sender::Transport;

eval { Email::Sender::Transport->new->send_email };
like($@, qr{method not implemented}, 'Transport is not a useful Transport');
