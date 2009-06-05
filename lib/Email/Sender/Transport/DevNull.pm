package Email::Sender::Transport::DevNull;
use Moose;
with 'Email::Sender::Transport';
# ABSTRACT: happily throw away your mail

=head1 DESCRIPTION

This class implements L<Email::Sender::Transport>.  Any mail sent through a
DevNull transport will be silently discarded.

=cut

sub send_email { return $_[0]->success }

__PACKAGE__->meta->make_immutable;
no Moose;
1;
