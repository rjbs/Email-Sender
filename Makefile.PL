use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Sender',
    AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Email/Sender.pm',
    ABSTRACT_FROM       => 'lib/Email/Sender.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Sender-* cover_db' },
);
