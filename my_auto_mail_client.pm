#!/usr/bin/perl
package my_auto_mail_client;
use warnings;
use strict;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (); 
our @EXPORT = qw( &foo &bar ); 
our $VERSION = "2.1";
 
sub foo {
  #hier passiert was ...
  return result;
}
 
sub bar
{
  #hier passiert auch was ...
  return result;
}
 
1;
