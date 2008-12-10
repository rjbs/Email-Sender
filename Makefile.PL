require 5.006001;
use inc::Module::Install;

name          'Email-Sender';
author        'Ricardo SIGNES <rjbs@cpan.org>';
license       'perl';
version_from  'lib/Email/Sender.pm';

# NON-CORE PREREQUISITES
requires('Mouse'           => 0.12); # isa=>class accepts subclasses; Squirrel
requires('Email::Abstract' => 3);    # XXX: really use Abstract?; 3 = \$str
requires('Net::SMTP'       => 0);
requires('List::MoreUtils' => 0);    # minimum version unknown; uniq
requires('Class::Method::Modifiers' => 0); # minimum version unknown; Failable

# SOON TO NOT BE PREREQUISIES
requires('Email::Address'       => 0);     # used for env-from-msg (::Simple)
requires('Email::Simple'        => 1.998); # XXX: needed(?) for ->header_obj
                                           # only needed my Mbox; split?
requires('Sys::Hostname::Long'  => 0);     # XXX: do we -need- a good HELO?

# XXX: REMOVE SQLite TRANSPORT TO ITS OWN DIST
requires('DBD::SQLite'          => 0);  # minimum unknown

# CORE PREREQUISITES
requires('Carp'           => 0);    # minimum unknown
requires('Cwd'            => 0);    # minimum unknown
requires('Fcntl'          => 0);
requires('File::Basename' => 0);
requires('File::Find'     => 0);
requires('File::Path'     => 0);
requires('File::Spec'     => 0);
requires('File::Temp'     => 0);
requires('FindBin'        => 0);
requires('Scalar::Util'   => 0);
requires('Test::More'     => 0);  # minimum unknown

auto_manifest;

WriteAll();
