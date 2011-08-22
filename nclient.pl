#!/usr/bin/perl -w
    use strict;
    use IO::Socket;
    use X11::GUITest qw(GetMousePos);
    my ($host, $kport, $mport, $kidpid, $key, $mouse);
    unless (@ARGV == 3) { die "usage: $0 host textport mouseport" }
    ($host, $kport, $mport) = @ARGV;
    # create a tcp connection to the specified host and port
    $key = IO::Socket::INET->new(Proto     => "tcp",
                                    PeerAddr  => $host,
                                    PeerPort  => $kport)
               || die "can't connect to port $kport on $host: $!";
#    $mouse = IO::Socket::INET->new(Proto     => "tcp",
#                                    PeerAddr  => $host,
#                                    PeerPort  => $mport)
#               || die "can't connect to port $mport on $host: $!";
#
    $key->autoflush(1);       # so output gets there right away
#    $mouse->autoflush(1);
    print STDERR "[Connected to $host:$kport]\n";
#    print STDERR "[Connected to $host:$mport]\n";
    print $key "password\n";
#    print $mouse "password\n";
    my $pid;
    if($pid = fork()){
	while(<STDIN>){
		print $key "K$_";
	}
	kill("TERM", $pid);
    }else{
	my ($x, $y, $s, $ox, $oy, $rx, $ry);
        ($x, $y, $s) = GetMousePos();
	($ox, $oy) = ($x, $y);
	while(1){
		($x, $y, $s) = GetMousePos();
		($rx, $ry) = ($x-$ox,$y-$oy);
#		print "$rx $ry\n";
		print $key "M$rx $ry\n" if($rx != 0 && $ry != 0);
		($ox, $oy) = ($x, $y);
#		sleep 0.5;
	}
    }
$SIG{INT} = sub {kill("TERM", $pid);}
