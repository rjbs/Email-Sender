use Test::More tests => 4;
use strict;
$^W = 1;

use lib 't/lib';

use File::Temp qw(tempfile);

use_ok('Email::Sender::IOAll');

my $message = <<"END_MESSAGE";
To: put-up
From: shut-up
Subject: jfdi

This is a test (message).
END_MESSAGE

my (undef, $filename) = tempfile(DIR => 't', UNLINK => 1);

my $sender = Email::Sender::IOAll->new({ dest => $filename });

ok($sender->send($message), 'send the first message');
ok($sender->send($message), 'and send it again');

open TEMPFILE, "<$filename" or die "couldn't open temp file: $!";

my @lines = <TEMPFILE>;

is(@lines, 10, "message delivered twice: nine lines in file");
