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
my $mouse = 0;
my $argbkup = @ARGV;
GetOptions("password=s" => \$pass, "port=i" => \$PORT, "daemon=s" => \$daemon, "mouse=i" => \$mouse);
if($daemon ne ""){
	close STDOUT;
	close STDERR;
	open STDOUT, ">> $daemon";
	open STDERR, ">> $daemon";
	exit if(fork());
}
my %OS = ("linux" => "linux", "darwin" => "mac", "MSWin32" => "windows");
my $writer = "writer/keys/$OS{$^O}.pl";
my $server = IO::Socket::INET->new( Proto     => "tcp",
		LocalPort => $PORT,
		Listen    => SOMAXCONN,
		Reuse     => 1);
die "can't setup server" unless $server;
print "[Server $0 accepting clients]\n";
# my $kpid = open(KEYS, "| writer/linux.pl");
my $client;
if(!fork()){
	my $mwriter = "writer/mouse/$OS{$^O}.pl";
	my $mserver = IO::Socket::INET->new( Proto     => "tcp",
			LocalPort => $mouse,
			Listen    => SOMAXCONN,
			Reuse     => 1);
	my $mclient;
print "[Server $0 accepting clients]\n";

	while($mclient = $mserver->accept()) {
		next if(fork());
		my $pid = fork();
		next if($pid);
		open(MOUSE, "| $mwriter");
		select MOUSE;
		$| = 1;
		select STDOUT;
#print KEYS "test";
		$mclient->autoflush(1);
		print $mclient "Welcome to keyHacker; type password.\n";
		my $hostinfo = gethostbyaddr($mclient->peeraddr);
		my $name = $hostinfo ? $hostinfo->name : $mclient->peerhost;
		print "[Connect from $name]\n";
		for(my $i = 0; $i < 5; $i++) {
			$_ = <$mclient>;
			chomp;
			next unless /\S/;       # blank line
				last if($_ eq $pass);
			print "[$name has tried to login ", $i+1, " times]\n";
			print $mclient "Incorrect password\n";
		}
		if($_ ne $pass){
			print "[$name failed to authenticate]\n";
			print $mclient "Authentication failure\n";
			close $mclient;
			exit;
		}
		print "[$name authenticated]\n";
		print $mclient "Authenticated, accepting movements\n";
		while(<$mclient>){
#			print;
			print MOUSE $_;
		}
		close MOUSE;
		exit;
	}
}
while ($client = $server->accept()) {
	my $pid = fork();
	next if($pid);
	open(KEYS, "| $writer");
	select KEYS;
	$| = 1;
	select STDOUT;
#print KEYS "test";
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
	print "[$name authenticated]\n";
	print $client "Authenticated, accepting keys\n";

	while(<$client>){
		print KEYS "$_";
	}
	close KEYS;
	close $client;
	print "[$name closed connection]\n";
	exit;
}
