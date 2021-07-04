#!perl
use strict;
use Test::More;

plan skip_all => "this test only runs during release"
  unless $ENV{RELEASE_TESTING};

eval {
  require Test::MinimumVersion;
  Test::MinimumVersion->VERSION(0.003);
  Test::MinimumVersion->import;
};

plan skip_all => "this test requires Test::MinimumVersion" if $@;

all_minimum_version_ok(5.012000);
