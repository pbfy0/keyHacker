#!/usr/bin/perl

use X11::GUITest qw/ SendKeys /;

while(<STDIN>){
	SendKeys($_);
}
