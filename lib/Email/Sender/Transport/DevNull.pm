package Email::Sender::Transport::DevNull;
use Moo;
with 'Email::Sender::Transport';
# ABSTRACT: happily throw away your mail

=head1 DESCRIPTION

This class implements L<Email::Sender::Transport>.  Any mail sent through a
DevNull transport will be silently discarded.

=cut

sub send_email { return $_[0]->success }

no Moo;
1;
