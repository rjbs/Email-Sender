package Email::Sender::Success;
use Moose;
# ABSTRACT: the result of successfully sending mail

=head1 DESCRIPTION

An Email::Sender::Success object is just an indicator that an email message was
successfully sent.  Unless extended, it has no properties of its own.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
1;
