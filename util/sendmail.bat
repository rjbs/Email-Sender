@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl
#line 15
use strict;
use warnings;

use File::Spec;
use File::Temp;

my $dir = $ENV{EMAIL_SENDER_TRANSPORT_SENDMAIL_TEST_LOGDIR} 
        || File::Temp::tempdir( CLEANUP => 1 );

my $logfile = File::Spec->catfile($dir, 'sendmail.log');

my $input = join '', <STDIN>;

open my $fh, '>', $logfile
  or die "Cannot write to logfile $logfile: $!";

print $fh "CLI args: @ARGV\n";
if (defined $input && length $input) {
  print $fh "Executed with input on STDIN\n$input";
} else {
  print $fh "Executed with no input on STDIN\n";
}


__END__
:endofperl
