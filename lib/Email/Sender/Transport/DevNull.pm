package Email::Sender::Transport::DevNull;
# ABSTRACT: happily throw away your mail

use Moo;
with 'Email::Sender::Transport';

=head1 DESCRIPTION

This class implements L<Email::Sender::Transport>.  Any mail sent through a
DevNull transport will be silently discarded.

=cut

sub send_email { return $_[0]->success }

no Moo;
1;
