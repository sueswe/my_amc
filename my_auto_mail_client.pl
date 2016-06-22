#!perl

my $VERSION = "0.2.1.0";

################################################################################
#
# Copyright (C) 2012-2016  Werner Süß <suess_w@gmx.net>
#
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
#
################################################################################

use warnings;
use strict;
use POSIX 'strftime';
use Cwd;
use Mail::Sender;
use Config::IniFiles;
use Archive::Zip qw(:ERROR_CODES);
use Getopt::Long;
use Email::MIME;
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Copy;
use Net::POP3;
use Log::Log4perl qw(:easy);

my $workDir = getcwd();
my $heute = POSIX::strftime('%Y%m%d', localtime);
my $logfile = $workDir . "//" . $heute . "-myamc.log";
our $dateiName;

## CONFIGURATIONSBLOCK Beginn ##################################################
$|=1;
our (   $ini_file, $USER, $PW, $POP3HOST, $POP_DEBUG,
        $pop, $ini, @filename_array, @subject,
        $SMTP, $FROM, $TO, $ERROR_RECIPIENT,
        $debug,
    );

my $configFile = 'amc.rc';
my $timestamp = POSIX::strftime('%Y%m%d-%H%M%S', localtime);
## CONFIGURATIONSBLOCK Ende ####################################################

for my $file ("$workDir//$configFile")
{
    unless (my $return = do $file) {
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!"    unless defined $return;
        warn "couldn't run $file"       unless $return;
    }
}

my $logLevel = "INFO";
my $logLayout = "%d %p> %m%n";
if ( defined $debug ) {
   $logLevel = "DEBUG";
   $logLayout = "%M %d %p> %m%n";
}

Log::Log4perl->easy_init(
{
    level => $logLevel,
    file => ">> $logfile",
    ###file => 'stdout',
    mode => "append",
    layout => $logLayout,
    }
);
my $log = get_logger();

INFO("\n my_auto_mail_client, version $VERSION");

chdir("$workDir") || ERROR("Cannot chdir $workDir: $!") && exit(99);
DEBUG("chdir to $workDir");

if (! -e $ini_file ) { 
    ERROR("ini-File not found!");
    inform_admin("ini-File not found!");
    exit(2) 
} else {
    DEBUG "ini-File found.";
}

GetOptions (
    'help|?'            => \my $help,
);

if ( defined $help ) {
    usage() && exit(1);
}

### MAIN #######################################################################
my $num_messages = connect_pop();
if ( $num_messages =~ m/0E0/ig ) {
    INFO "No messages."; exit(1);
} else {
    INFO "Messages: $num_messages";
}



# for each email:
for my $i ( 1 .. $num_messages ) {
    INFO("processing message $i ");
    my $aref = $pop->get($i);
    my $message = $_;
    my $em = Email::MIME->new( join '', @$aref );

    #
    # find Subject:
    #
    my ($subject,$from);
    my $headpointer = $pop->top($i);
    foreach my $line (@{$headpointer}) {
        chomp($line);
        if ( $line =~ m/subject/ig ) { 
            $subject = $line; 
        } elsif ( $line =~ m/^From:/ig ) {
            $from = $line;
            DEBUG("From: $from");
        }
    }
    INFO("$subject");
    $subject =~ s/\s//ig; $subject =~ s/subject//ig; $subject =~ s/://ig; $subject =~ s/\?//ig;
    $subject = substr($subject,0,15);
    
    #
    # read ini:
    #
    my @sections = $ini->Sections();
    my $notfound_counter = 0;
    #
    # for each ini section:
    #
    foreach (@sections) {
        my $cur_sec = $_;
        INFO("# SECTION IN INI: $cur_sec #");
        
        my $ini_subject = $ini->val($_,'subject');
        INFO("INI-Subject: $ini_subject");

        my $bodySaveDir = $ini->val($_,'body_save');
        
        my $attachment_dir = $ini->val($_,'attachment_save_dir');
        
        my $unzip_yn = $ini->val($_,'attachment_unzip');
        
        
        #
        # found ini entry:
        #
        if ($subject =~ m/\Q$ini_subject/ig ) {
            DEBUG("Subject found in INI file");
            
            #
            # saving the From line:
            #
            $dateiName = "\\" . $timestamp . "_" . $subject .".txt";
            DEBUG("Saving From to filename " . $bodySaveDir . $dateiName);
            open(FH,"> ".$bodySaveDir.$dateiName) || ERROR("Can not write FH $bodySaveDir$dateiName : $!");
            print FH "$from \n";
            close(FH);

            #
            # saving the Body:
            #
            my $bodyFile;
            if ( ! defined $bodySaveDir ) {
                ERROR("storage location emails not configured in ini-file.");
                exit(2);
            } else {
                INFO("storage location for emails: $bodySaveDir");
                $bodyFile = save_body($em,$bodySaveDir);
            }
            
            
            my $anhang;
            if ( ! defined $attachment_dir ) {
                DEBUG("Do not save attachments.");
            } else {
                INFO("storage location for attachments: $attachment_dir");
                $anhang = save_attachment($em,$attachment_dir);
            }
            
            
            if ( ! defined $unzip_yn ) {
                DEBUG("Do not unzip zip-files"); 
            } else {
                DEBUG("Unzip zip-files: $unzip_yn");
                unzip_attachment("$anhang","$attachment_dir");
            }
            
            
            my @action = $ini->val($cur_sec,'action');
            DEBUG("fireing up: @action $bodyFile");
            my $externReturncode = start_process_action("@action","$bodyFile");
            INFO("Returncode was: $externReturncode");
            # done.
            $notfound_counter = 0;
            last;
        } else {
            $notfound_counter += 1;
            DEBUG("notfound_counter: $notfound_counter");
        }
    } # foreach section
    
    #
    # delete email
    #
    INFO "Deleting message $i ";
    $pop->delete($i) || ERROR("Cannot delete message!") && die("ERROR: Cannot delete message!");
    
    
} #for email $i

#
# if $notfound_counter > 0 
#


#
# close POP connection:
#
$pop->quit();




### SUBROUTINEN ################################################################

sub save_body {
    my ($em,$wo) = @_;
    
    DEBUG("$em, $wo");
    make_path("$wo");
    
    for ( my @parts = $em->parts ) {
        my $CONTYP = $_->content_type;
        DEBUG("Content-type: $CONTYP");

        
        if ( $_->content_type =~ m(^multipart/alternative|^multipart/related)i ) {
            my @bodyContent;
            my @subp = $_->subparts;
            for my $href ( @subp) {
                my %hash = %$href;
                foreach my $k (keys %hash) {
                    push(@bodyContent,$hash{$k});
                }
            }
            
            open(FH,">> $wo" . $dateiName ) || WARN("Cannot write file $wo : $!");
              DEBUG("saving body to: $wo". $dateiName);
              print FH "@bodyContent";
            close(FH);
        } elsif ( $_->content_type =~ m(^text/plain|^text/html)i ) {
            my  @body = $_->body;
            open(FH,">> $wo" . $dateiName ) || WARN("Cannot write file $wo : $!");
              DEBUG("saving body to: $wo". $dateiName);
              print FH "@body";
            close(FH);
        } else {
            DEBUG("Do not save this content-type as body ($CONTYP)");
        }
    }
    # returnvalue is body-file:
    $wo .= $dateiName;
    DEBUG("returnvalue = $wo");
    return($wo);
}

sub save_attachment {
    my ($em,$dir) = @_;
    make_path("$dir");
    my $attachmentFile = "N/A";
    DEBUG "saving attachment to: $dir";
    for ( my @parts = $em->parts ) {
        my $contType = $_->content_type;
        if ( $contType =~ m(^multipart/alternative|^multipart/related|^text/plain|^text/html)i ) {
            #DEBUG("Do not save this content-type as attachment ($contType)");
        } else {
            $attachmentFile = $_->filename;
            DEBUG("attachmentFile: $dir//$attachmentFile");
            open my $fh, ">>", $dir."//".$attachmentFile || ERROR("save: $! ")
                && mailit("Problem beim speichern eines Anhangs","$!") && ERROR("while saving attachment: $!\n");
            binmode $fh;
            print $fh $_->body;
            close $fh;
        }
    }
    #push(@alle_attachment_namen,$filename);
    return("$dir//$attachmentFile");
}

sub unzip_attachment {
    my ($thisFile,$dir) = @_;
    chdir("$dir") || ERROR("Cannot chdir to $dir: $!");
    if ( $thisFile =~ m/zip$/ig ) {
        INFO "Entpacke $thisFile ...";
        my $zip = Archive::Zip->new();
        my $zipName = $thisFile;
        my $status  = $zip->read($zipName);
        if ( $status != AZ_OK ) {
            ERROR "Read of $zipName failed";
        } else {
            my @inhalt = $zip->memberNames();
            foreach (@inhalt) {
                DEBUG "$_";
            }
            foreach my $member ($zip->members) {
                $zip->extractMember($member);
                if ( $status != AZ_OK ) {
                    ERROR "kann $member nicht entpacken";
                    mailit("Unzip Error: kann $member nicht entpacken.","n/a");
                }
            } #foreach member
        }
    } else {
        WARN "unzip: $thisFile is not a zip-file.";
    }
}

sub start_process_action {
    my ($what,$withWhat) = @_;
    DEBUG("Starting $what");
    open(FH,"-|","$what $withWhat") || WARN("Cannot find $what") && return(4);
    my $c = 1;
    while(<FH>) {
        my $out .= $_;
        INFO("$c: $out");
        $c++;
    }
    close(FH) || WARN("error while closing process-filehandle ($what) $!");
    my $RTC = $? >> 8;
    if ( $RTC != 0 ) { ERROR("process returned with rtc = $RTC"); }
    return($RTC);
}

sub connect_pop {
    # Verbindung zum POP Server aufbauen
    INFO "Connecting to server $POP3HOST";
    $pop = Net::POP3->new($POP3HOST);
    ERROR("Couldn't connect to the server \"$POP3HOST\" , $! !\n")
        && die "Couldn't connect to the server \"$POP3HOST\" , $! !\n"
        && mailit("Couldn't connect to the server \'$POP3HOST\'","$!")
        unless $pop;

    # Login to POP server
    INFO "Login as user $USER";
    my $num_messages = $pop->login( $USER, $PW );
    ERROR("Connection trouble network password user ! \n")
        && die "Connection trouble network password user ! \n"
        && mailit("Connection trouble network password user","$!")
        unless defined $num_messages;

    return($num_messages);
}

sub inform_admin {
    my $TEXT = shift;
    my $sender = new Mail::Sender {
        smtp => $SMTP,
        from => $FROM,
        debug => 0,
        tls_allowed => 0,
        on_errors => undef,
        } or ERROR("Cannot create Email: $!") && die("Can't create the Mail::Sender object: $Mail::Sender::Error\n");
    $sender->Open({
        to => $TO,
        # cc => 'somebody@somewhere.com',
        subject => "Problem with $0 !"
        }) or die "Can't open the message: $sender->{'error_msg'}\n";
    $sender->SendLineEnc("$TEXT");
    $sender->Close() or ERROR("Cannot send email!") && die("Failed to send the message: $sender->{'error_msg'}\n");
    return(0);
}

sub mailit {
    my ($SUBJECT,$MESSAGE,$mailrecipients) = @_;
    if ( ! defined $mailrecipients ) {
        $mailrecipients = $ERROR_RECIPIENT;
    }
    print "(sending Email to $mailrecipients)\n";
    my $sender = new Mail::Sender {
        smtp => $SMTP,
        from => $FROM,
        priority => 2,
        #debug => "c:\\temp\\mail-sender.log",
        on_errors => undef,
        } or die("Can't create the Mail::Sender object: " . $Mail::Sender::Error );
    $sender->Open({
        to => "$mailrecipients",
        #cc => 'somebody@somewhere.com',
        subject => "new_auto_mail_client: ".$SUBJECT,
        }) or die "Can't open the message: $sender->{'error_msg'}\n";
    $sender->SendLineEnc("$MESSAGE \n---\n\n(This is an autogenerated message)\nPlease reply to: rz.om.stp\@itsv.at");
    $sender->Close();
}

sub usage {
    print <<EOF;
 Usage:
  $0 
  
  Saves Emails as text, saves the attachments and starts an 
  postprocess, with the txt-file as parameter.

  Configfile: $configFile
  INI-file:   $ini_file

EOF
}





