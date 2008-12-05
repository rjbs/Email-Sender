use strict;
use warnings;
package Test::Email::Sender::Util;
use Exporter;
BEGIN { our @ISA = qw(Exporter) }

our @EXPORT = qw(readfile);

sub readfile {
  my ($name) = @_;
  open my $msg_file, "<$name" or die "coudn't read $name: $!";
  my @lines = <$msg_file>;
  close $msg_file;
  return \@lines;
}

1;
