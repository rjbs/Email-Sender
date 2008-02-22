use strict;
use warnings;

use inc::Module::Install;

name          'Email-Sender';
author        'Ricardo SIGNES <rjbs@cpan.org>';
license       'perl';
version_from  'lib/Email/Sender.pm';

requires('Email::PEP::Base' => 0); # unknown minimum

WriteAll();
