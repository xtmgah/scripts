#!/usr/bin/env perl
# wrapper script for qmake to remove newlines

use strict;
use warnings;
use Cwd;

my $cwd = getcwd;
my $email_addrs = "qmake\@raylim.mm.st";

sub HELP_MESSAGE {
    print "Usage: qmake.pl -n [name] -m -r [numAttempts]\n";
    print "-m: e-mails notifications to $email_addrs\n";
    print "-r: number of attempts (default: 1)\n";
    print "-l: parent log dir (default: log)\n";
    print "-n: job name\n";
    exit(1);
}


use File::Basename;
use File::Glob ':glob';
use File::Path;

use Getopt::Std;

my %opt;

getopts('n:mr:l:', \%opt);

my $attempts = 1;
my $name = "qmake";
my $logparent = "log";
$attempts = $opt{r} if defined $opt{r};
$name = $opt{n} if defined $opt{n};
$logparent = $opt{l} if defined $opt{l};

my $qmake = shift @ARGV; 

my $args = join " ", @ARGV;

# makefile processing
=pod
my $orig_args = $args;

$args =~ s;-f (\S+);"-f " . dirname($1) . "/." . basename($1) . ".tmp";e;
my $optf = $1;

my @makefiles;
if (defined $optf) {
    push @makefiles, $optf;
} else {
    if ($args =~ /--/) {
        $args .= " -f .Makefile.tmp";
    } else {
        $args .= "-- -f .Makefile.tmp";
    }
    push @makefiles, "Makefile";
}



do {
    my $makefile = glob(shift(@makefiles));
    
    open IN, "<$makefile" or die "Unable to open $makefile\n";
    my $tmpfile = glob(dirname($makefile) . "/." . basename($makefile) . ".tmp");
    open OUT, ">$tmpfile" or die "Unable to open $tmpfile\n";
    while (<IN>) {
        s/\\\n$//;
        if (!/^include \S+\.tmp/ && s;^include (\S+);"include " . dirname($1) . "/." . basename($1) . ".tmp";e) {
            push @makefiles, $1;
        }
        print OUT $_;
    }
} until (scalar @makefiles == 0);
=cut

my $n = 0;
my $retcode;
do {
    my $logdir = "$logparent/$name";
    my $logfile = "$logdir.log";
    my $i = 0;
    while (-e $logdir || -e $logfile) {
        $logdir = "log/$name.$i";
        $logfile = "$logdir.log";
        $i++;
    }
    mkpath $logdir;
    my $pid = fork;
    if ($pid == 0) {
        #print "$qmake $args &> $logfile\n";
        exec "$qmake $args LOGDIR=$logdir &> $logfile";
    } else {
        my $mail_msg = "Command: $qmake $args\n";
        $mail_msg .=  "Attempt #: " . ($n + 1) . " of $attempts\n";
        $mail_msg .=  "Hostname: " . $ENV{HOSTNAME}. "\n";
        $mail_msg .=  "PID: $pid\n";
        $mail_msg .=  "Dir: $cwd\n";
        $mail_msg .=  "Log dir: $cwd/$logdir\n";
        $mail_msg .=  "Log file: $cwd/$logfile\n";

        if ($opt{m}) {
            my $mail_subject = "$name: job started ($cwd)";
            $mail_subject .= " Attempt " . ($n + 1) if $n > 0; 
            open(MAIL, "| mail -s '$mail_subject' $email_addrs");
            print MAIL "$mail_msg";
            close MAIL;
        }
        waitpid(-1, 0);
        $retcode = $? >> 8; # shift bits to get the real return code
        if ($opt{m}) {
            my $mail_subject = "$name: job finished [$retcode] ($cwd)";
            $mail_subject .= " Attempt " . ($n + 1) if $n > 0; 
            open(MAIL, "| mail -s '$mail_subject' $email_addrs");
            print MAIL "Return code: $retcode\n";
            print MAIL "$mail_msg";
            close MAIL;
        }
    }
} while ($retcode && ++$n < $attempts);
exit($retcode);
