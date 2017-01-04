
[![Build Status](https://travis-ci.org/sueswe/my_amc.svg?branch=travis)](https://travis-ci.org/sueswe/my_amc)

# My Auto Mail Client - Start actions via email.

## 0) Intro ##

I wrote this stuff for automation purposes, in combination  
with a jobcontrol tool. The idea exists, but I needed something more flexible. And I want fully control what's going on.

## 1) How it should work ##

Looks for an email on a POP3-server, and starts an action when the
subject of the email fits to a keyword defined in the filter.ini-file.
It always saves the email (and deletes it on the POP3-Server).
It's also possible to save attachments and unzip them.
You can restrict actions in the filter.ini file to emailaddresses,
so not every sender is allowed to run every command.


## 2) Installation ##

### 2.1) Windows ###

For the use as a windows service I wrote a myAMCd - script.
Install the with
* nssm ([http://nssm.cc](http://nssm.cc)):


    nssm install myAMCD C:\strawberry\perl\bin\perl.exe C:\batch\Opcon\scripts\myAMC\myAMCd.pl C:\\batch\\Opcon\\scripts\\myAMC\\my_auto_mail_client.pl 60


So, what is going on here: myAMCd will start my_auto_mail_client.pl every sixty seconds.
nssm is really awesome, so please support it.
It installs perl with the command line options as an service.
This example refers to a strwaberry installation.

### 2.1) Linux ###

Install it as a Linux daemon, therefor you may write an init-script. Or just fire it up with:

    perl /path/to/myAMDc.pl /path/to/my_auto_mail_client.pl 60

## 3.0) Configuration ##

### 3.1) amc.rc ###

Section One: set debuglevel to 'true' or 'false'.

Section Two: the name of your filer.ini file.

Section Three: POP3 server settings.

Section Four: SMTPD server settings.

And that's it.

## 4.0) Help ##

If you need help, please open a ticket here on github:

https://github.com/sueswe/my_amc/issues/new
