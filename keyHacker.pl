#!/usr/bin/perl -w
$| = 1;
use strict;
use IO::Socket;
use Net::hostent;      # for OOish version of gethostbyaddr
use Getopt::Long;
use File::Basename;
#  use X11::GUITest qw/ SendKeys /;
chdir dirname($0);
my $pass = "password";
my $PORT = 9000;          # pick something not in use
my $daemon = "";
my $argbkup = @ARGV;
GetOptions("password=s" => \$pass, "port=i" => \$PORT, "daemon=s" => \$daemon);
if($daemon ne ""){
	close STDOUT;
	open STDOUT, "> $daemon";
	exit if(fork());
}
my %OS = ("linux" => "linux", "darwin" => "mac", "MSWin32" => "windows");
my $writer = "writer/keys/$OS{$^O}.pl";
my $mwriter = "writer/mouse/$OS{$^O}.pl";
my $server = IO::Socket::INET->new( Proto     => "tcp",
		LocalPort => $PORT,
		Listen    => SOMAXCONN,
		Reuse     => 1);
die "can't setup server" unless $server;
print "[Server $0 accepting clients]\n";
# my $kpid = open(KEYS, "| writer/linux.pl");
my $client;
my %pids = ();
$SIG{CHLD} = \&kchld;
while ($client = $server->accept()) {
	my $pid = -1;
	my $tch;
	$pid = open($tch, "|-") if(scalar(keys %pids) < 10000);

	if($pid){
		$pids{$pid} = 1;
		print $tch $pid;
		close($tch);
		next;
	}
#	open(KEYS, "| $writer");
#	select KEYS;
#	$| = 1;
#	select STDOUT;
#print KEYS "test";
	my $cpid = <STDIN>;
	$client->autoflush(1);
	print $client "Welcome to keyHacker; type password.\n";
	my $hostinfo = gethostbyaddr($client->peeraddr);
	my $name = $hostinfo ? $hostinfo->name : $client->peerhost;
	print "[Connect from $name]\n";
	for(my $i = 0; $i < 5; $i++) {
		$_ = <$client>;
		chomp;
		next unless /\S/;       # blank line
			last if($_ eq $pass);
		print "[$name has tried to login ", $i+1, " times]\n";
		print $client "Incorrect password\n";
	}
	if($_ ne $pass){
		print "[$name failed to authenticate]\n";
		print $client "Authentication failure\n";
		close $client;
		exit;
	}
        open(KEYS, "| $writer");
	open(MOUSE, "| $mwriter");
        select KEYS;
        $| = 1;
	select MOUSE;
	$| = 1;
        select STDOUT;
	print "[$name authenticated]\n";
	print $client "Authenticated, accepting keys\n";

	while(<$client>){
		my $t = substr($_, 0, 1);
		my $c = substr($_, 1);
		if($t eq "K"){
			print KEYS "$c";
		}elsif($t eq "M"){
			print MOUSE "$c";
		}
	}
	close KEYS;
	close MOUSE;
	close $client;
	print "[$name closed connection]\n";
	delete $pids{$cpid};
#	kill("TERM", $$);
	exit;
}
sub kchld{
foreach(keys %pids){
	kill("TERM", $_);
}
}
