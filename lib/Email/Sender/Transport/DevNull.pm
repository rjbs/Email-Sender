package Email::Sender::Transport::DevNull;
use Moose;
with 'Email::Sender::Transport';

our $VERSION = '0.004';

=head1 NAME

Email::Sender::Transport::DevNull - happily throw away your mail

=cut

sub send_email { return $_[0]->success }

__PACKAGE__->meta->make_immutable;
no Moose;
1;
