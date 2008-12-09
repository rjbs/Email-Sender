#!perl
use strict;
use warnings;
use Test::More tests => 5;

use Email::Abstract;
use Email::Simple;
use Email::Sender::Transport;

my $email = <<'EOF';
To: Casey West <casey@example.com>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

# SIMPLE
my $simple      = Email::Simple->new($email);
my $prep_simple = Email::Sender::Transport->prepare_email($simple);
is($prep_simple->as_string, $simple->as_string, 'simple - strings same');

# ABSTRACT
my $abstract      = Email::Abstract->new($email);
my $prep_abstract = Email::Sender::Transport->prepare_email($abstract);
is($prep_abstract->as_string, $abstract->as_string, 'abs - strings same');
ok($abstract == $prep_abstract, 'Email::Abstract object is not re-rewrapped');

# STRING
my $prep_string = Email::Sender::Transport->prepare_email($email);
is($prep_string->as_string, $email, 'string - strings same');

# STRING REF
my $copy = $email;
my $prep_string_ref = Email::Sender::Transport->prepare_email(\$copy);
is($prep_string_ref->as_string, $email, 'stringref - strings same');
