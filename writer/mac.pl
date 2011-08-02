#!/usr/bin/perl

use Mac::Glue;
my $seglue = Mac::Glue->new('System Events');

while(<STDIN>){
	$seglue->keystroke($_);
}
