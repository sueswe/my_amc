
# My Auto Mail Client - Start actions via email.

## 0) Intro ##

I wrote this stuff for automation purposes, in combination  
with a jobcontrol tool. The idea exists, but I needed something more flexible. And I want full control
over what's going on.

## 1) How it should work ##

Looks for an email on a POP3-server, and starts an action when the
subject of the email fits to a keyword defined in the filter.ini-file.
It always saves the email (and deletes it on the POP3-Server).
It's also possible to save attachments and unzip them.
You can restrict actions in the filter.ini file to emailaddresses,
so not every sender is allowed to run every command.


## 2) Installation ##

### 2.0) Requirements

You need following perl-modules:

  * Log::Log4perl
  * Mail::Sender
  * Config::IniFiles
  * Archive::Zip
  * Getopt::Long
  * Email::MIME
  * File::Basename
  * File::Path
  * File::Copy
  * Net::POP3
  * Win32::Console;
  * use Win32::OLE;
  * use Encode;


Install them via cpan.


### 2.1) Windows ###

For the use as a windows service I wrote a myAMCd - script.
Install the with nssm ([http://nssm.cc](http://nssm.cc)):

    nssm install myAMCD C:\strawberry\perl\bin\perl.exe
      C:\batch\Opcon\scripts\myAMC\myAMCd.pl C:\\batch\\Opcon\\scripts\\myAMC\\my_auto_mail_client.pl 60

So, what is going on here: myAMCd will start my_auto_mail_client.pl every sixty seconds.
nssm is really awesome, so please support it.
It installs perl with the command line options as an service.
This example refers to a strawberry installation.

### 2.1) Linux ###

Install it as a Linux daemon, therefor you may write an init-script. Or just fire it up with:

    perl /path/to/myAMDc.pl /path/to/my_auto_mail_client.pl 60 &

## 3.0) Configuration ##

### 3.1) amc.rc ###

The configuration file is always amc.rc . It has to be
located in the current directory.
If you want to change the name and/or the name of the
configuration file you have to make a change in
the my_auto_mail_client.pl file.


* Section One: set debuglevel to 'true' or 'false'.

* Section Two: the name of your filer.ini file.

* Section Three: POP3 server settings.

* Section Four: SMTPD server settings.

And that's it.

### 3.2) INI's ###

To configure what should happen, you have to edit the
master.ini file.
You can also use a directory and place many individual ini-files
in it, for example an ini-file for every project.

The ini has to contain at least following filter informations:

    from=name@smtp.org
    subject=foo
    action=c:\temp\test_one.cmd
    body_save=c:\mail-directory\

When ever an email comes from name@smtp.org with the
subject-string foo in any part of the subject,
then the email will be saved in c:\mail-directory\
and following command will be started:

    c:\temp\test_one.cmd c:\mail-directory\email-body-file

You can also save the attachments into a special
directory, and send emails to special recipients, if
the started process failes.

Description of ini-values:

    from=                   Allowed email-adress
    subject=                Trigger-subject
    action=                 What to start
    body_save=              directory where to save the emails
    attachment_save_dir=    directory where to save the attachments
    attachment_unzip=       unzip attachments yes/no
    fail_address=           adress to send alerts to
    fail_subject=           alert-subject
    fail_body=              alert-body-text
    send_this_log=          logfile to send to the alert-adress

## 4.0) Help ##

If you need help, please open an issue here on github:
https://github.com/sueswe/my_amc/issues/new

