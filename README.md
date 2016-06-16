
# My Auto Mail Client - Start actions via email.

## 0) Intro ##

I wrote this stuff for automation purposes, in combination  
with a jobcontrol tool. The idea exists, but I needed something more flexible.

## 1) How it should work ##

Looks for an email on a POP3-server, and starts an action when the
subject of the email fits to a keyword defined in the filter.ini-file.
It always saves the email (and deletes it on the POP3-Server).
It's also possible to save attachments and unzip them.

## 2) Installation (e.g. Windows Server 2008) ##

For the use as a service I write a myAMCd - script.
Install the with
* nssm ([http://nssm.cc](http://nssm.cc)):

    nssm install myAMCD C:\strawberry\perl\bin\perl.exe C:\batch\Opcon\scripts\myAMC\myAMCd.pl C:\\batch\\Opcon\\scripts\\myAMC\\my_auto_mail_client.pl 60





