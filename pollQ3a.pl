#! /usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use IO::Socket::INET;

my $server = '10.0.200.2';
my $port = '27960';

my $msg = "\xFF\xFF\xFF\xFF\x02getstatus\x0a\x00";

my $result = GetOptions ("server=s" => \$server,
                      "port=s" => \$port);

my $socket = new IO::Socket::INET (
    PeerAddr   => $server,
    PeerPort => $port,
    Proto => 'udp',
    Blocking=>0
) or die 'ERROR in Socket Creation : '.$!."\n";

$socket->send($msg);

sleep(1);

my $data = '';

for(my $c=0; $c <= 42; $c++){
    
    my  $tmp = <$socket>;
    if($tmp){
        $data = $data.$tmp;
    }
}

if($data){
    my @parstrings = split('\n', $data);   
    my @serverdata = split('\\\\', $parstrings[1]);    
    my %serverinfo;

    for(my $i=1; $i <= $#serverdata; $i=$i+2){
        $serverinfo{$serverdata[$i]} = $serverdata[$i+1];
        #print $serverdata[$i]."\n";
    }
    print "Server ".$serverinfo{'sv_hostname'}.":\n";
    print "\tMap: ".$serverinfo{'mapname'}."\n";
    
    my $gametype; 
    if($serverinfo{'g_gametype'} eq '0'){
        $gametype = 'FreeForAll';
    }
    if($serverinfo{'g_gametype'} eq '1'){
        $gametype = 'DM';
    }
    if($serverinfo{'g_gametype'} eq '2'){
        $gametype = '1on1';
    }
    if($serverinfo{'g_gametype'} eq '3'){
        $gametype = 'TeamDM';
    }
    if($serverinfo{'g_gametype'} eq '4'){
        $gametype = 'CTF';
    }
    
    print "\tGametype: ".$gametype. "\n";
    
    if($serverinfo{'g_gametype'} eq '4'){
        print "\tCapture Limit: ".$serverinfo{'capturelimit'}."\n";
    }else{
        print "\tFrag Limit: ".$serverinfo{'fraglimit'}."\n";  
        
    }
    
    print "\tTime Limit: ".$serverinfo{'timelimit'}."\n";

    if($serverinfo{'g_needpass'} ne '0'){    
        print "\tGame is password protected!\n";
    } 
    
    print "\tFree Slots: ".( $serverinfo{'sv_maxclients'} - ($#parstrings - 2)). " / " .  $serverinfo{'sv_maxclients'} . "\n";

    print "\n";
    if($#parstrings > 2){
        print("Players:\n");
        for(my $c=2; $c <= $#parstrings; $c++){
            my @player = split(' ', $parstrings[$c]);
            print "\tName: ".$player[2]." Frags: ". $player[0]." Ping: ". $player[1]."\n";
        }
    }
}else{
    print "Server not available\n";
}

$socket->close();