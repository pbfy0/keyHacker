#!/usr/bin/perl

use Win32::GuiTest qw/ SendKeys /;

while(<STDIN>){
	SendKeys($_);
}
