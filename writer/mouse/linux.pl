#!/usr/bin/perl

use X11::GUITest qw/ MoveMouseAbs GetMousePos /;
my ($x, $y, $s, $cx, $cy);
open FH, ">test";
while(<STDIN>){
#	print FH $_;
	chomp;
	($cx, $cy) = split(" ", $_);
	($x, $y, $s) = GetMousePos();
	($x, $y) = ($cx + $x, $cy + $y);
	MoveMouseAbs($x, $y);
}
