package Email::Sender::Failure;
use Squirrel;

sub throw {
  my $inv = shift;
  die $inv if ref $inv;
  die $inv->new(@_);
}

no Squirrel;
1;
