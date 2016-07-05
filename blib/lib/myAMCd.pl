#!perl

# Daemon-Script for myAMC.pl 

# Copyright (C) 2011-2016  Werner Süß
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#############################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);
use File::Basename;
use POSIX 'strftime';
use Cwd;

my $LOG_DIR = cwd();
my $heute   = POSIX::strftime('%Y%m%d', localtime);
my $logfile = $LOG_DIR."\\".$heute."_myAMCdaemon.log";

Log::Log4perl->easy_init(
{
    # levels from low to high:
    level => $DEBUG,
    #level => $INFO,
    #level => $WARN,
    #level => $ERROR,
    #level => $FATAL,
    file => ">> $logfile",
    #file => 'stdout',
    mode => "append",
    layout => "%d %p> %m%n",
    }
);
my $log = get_logger;

if ( ! defined $ARGV[0] || ! defined $ARGV[1] ) {
    ERROR "Missing argument";
    usage() && exit(1); 
}

# The Perl Executeable (not even for perl2exe):
my $perl = $^X;
INFO("Perl: $perl");

# what should be executed:
my $daemon = "$ARGV[0]";
my $WORK_DIR = dirname("$daemon");
chdir("$WORK_DIR");
INFO("WORKDIR: $WORK_DIR");

# run it every $intervall seconds:
my $intervall = "$ARGV[1]";

# optional: argument list for $daemon
my @arglist;
if ( defined $ARGV[2] ) { 
    @arglist = "$ARGV[2]"; 
}

if (! -e $daemon) {
    ERROR("Program \'$daemon\' not found");
    exit(2);
}


while(1) {
    $log->info("Awaking");
    $log->info("$perl $daemon @arglist");
    open(FH, "|-", "$perl $daemon @arglist" ) or ERROR("Cannot call script!") && die();
    # do not log the output:
    while (<FH>) {
        DEBUG "$_\n";
    }
    close(FH);
    $log->info("Sleeping for $intervall seconds");
    sleep($intervall);
}


############################################################################
sub usage 
############################################################################
{
    print "\nUsage:\n";
    print "    $0 program call-intervall program-arguments\n";
    print "\nExample:\n";
    print "    myAMCd.pl /usr/bin/ls 60 -l -t -r\n";
    print "    (runs \'ls -l -t -r\' every 60 seconds)\n";
}

