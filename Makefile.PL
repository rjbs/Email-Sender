require 5.006001;
use inc::Module::Install;

name          'Email-Sender';
author        'Ricardo SIGNES <rjbs@cpan.org>';
license       'perl';
version_from  'lib/Email/Sender.pm';

# REAL PREREQUISITES
requires('Mouse'           => 0.12); # isa=>class accepts subclasses; Squirrel
requires('Email::Abstract' => 0);    # XXX: really use Abstract?
requires('Email::Address'  => 0);    # used for envelope-from-msg
requires('Net::SMTP'       => 0);

# SOON TO NOT BE PREREQUISIES
requires('Class::Trigger'       => 0);     # XXX: ditch this, inline something
requires('Email::LocalDelivery' => 0);     # XXX: inline code, deprecate E:LD
requires('Email::Simple'        => 1.998); # XXX: needed(?) for ->header_obj
requires('Params::Util'         => 0);     # XXX: not really needed anymore?
requires('Sys::Hostname::Long'  => 0);     # XXX: do we -need- a good HELO?
requires('Params::Validate'     => 0);     # XXX: REMOVE THIS

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

WriteAll();
