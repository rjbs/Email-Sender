use Test::More tests => 3;
use strict;
$^W = 1;

use lib 't/lib';

use File::Temp;

use_ok('Email::Sender::IO');

my $message = <<"END_MESSAGE";
To: put-up
From: shut-up
Subject: jfdi

This is a test (message).
END_MESSAGE

my (undef, $filename) = tempfile(DIR => 't', UNLINK => 1);

{ my @no_warning_please = @Email::Send::IO::IO; }
@Email::Send::IO::IO = ($filename);

my $sender = Email::Send->new({ mailer => 'IO' });

ok($sender->send($message), 'send the first message');
ok($sender->send($message), 'and send it again');

open TEMPFILE, "<$filename" or die "couldn't open temp file: $!";

my @lines = <TEMPFILE>;

is(@lines, 10, "message delivered twice: nine lines in file");
