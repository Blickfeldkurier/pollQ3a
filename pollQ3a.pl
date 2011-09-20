#! /usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use IO::Socket::INET;
use Pod::Usage;

# for documentation 
my $help = 0;
my $man = 0;

# set default server and port
my $server = '10.0.200.2';
my $port = '27960';

my $exec = '';

# message to send to quake server
my $msg = "\xFF\xFF\xFF\xFF\x02getstatus\x0a\x00";

# get all the options from the command line
my $result = GetOptions ("server=s" => \$server,
                         "port=s"   => \$port,
                         "exec=s"   => \$exec,
                         "help"     => \$help,
                         "man"      => \$man
              );

# display help 
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

# create a new nonblocking socket
my $socket = new IO::Socket::INET (
    PeerAddr   => $server,
    PeerPort => $port,
    Proto => 'udp',
    Blocking => 0
) or die 'ERROR in Socket Creation : '.$!."\n";

# send the message to the server
$socket->send($msg);

# idle some small amount of time.
sleep(1);

# all recived data
my $data = '';

# catch all data comming our way
for(my $c=0; $c <= 42; $c++){
    
    my  $tmp = <$socket>;
    if($tmp){
        $data = $data.$tmp;
    }
}

# close the socket
$socket->close();

# process recived data
if($data){
    my @parstrings = split('\n', $data); # split the server info from the player info  
    my @serverdata = split('\\\\', $parstrings[1]); # split the server info 
    my %serverinfo; # hash holding all status variables

    # fill the %serverinfo hash
    for(my $i=1; $i <= $#serverdata; $i=$i+2){ # $i is the key, $i+1 the value
        $serverinfo{$serverdata[$i]} = $serverdata[$i+1];
    }

    #print hostname + mapname
    print "Server ".$serverinfo{'sv_hostname'}.":\n";
    print "\tMap: ".$serverinfo{'mapname'}."\n";
    
    # print gametype acording to g_gametype
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
    
    # print either the capture limit or the frag limit, depending on gametype
    if($serverinfo{'g_gametype'} eq '4'){
        print "\tCapture Limit: ".$serverinfo{'capturelimit'}."\n";
    }else{
        print "\tFrag Limit: ".$serverinfo{'fraglimit'}."\n";  
        
    }
    
    # print time limit
    print "\tTime Limit: ".$serverinfo{'timelimit'}."\n";

    # inform the user if the server is password protected
    if($serverinfo{'g_needpass'} ne '0'){    
        print "\tGame is password protected!\n";
    } 
    
    #print the free slots 
    # Nummber of current players = parstrings length -2 
    # (0,1 are server stats. The rest are player data) 
    print "\tFree Slots: ".( $serverinfo{'sv_maxclients'} - ($#parstrings - 2)). " / " .  $serverinfo{'sv_maxclients'} . "\n";
    print "\n";

    # Print Player informations
    if($#parstrings > 2){
        print("Players:\n");
        for(my $c=2; $c <= $#parstrings; $c++){
            my @player = split(' ', $parstrings[$c]);
            print "\tName: ".$player[2]." Frags: ". $player[0]." Ping: ". $player[1]."\n";
        }
    }

    #if exec string is given replace the server, port and run the thing
    if($exec){
        $exec =~ s/\$server/$server/;
        $exec =~ s/\$port/$port/;
        print ("Execute: ".$exec."\n");
        exec($exec);
    }

}else{# if $data is empty, there is no server available
    print "Server not available\n";
}

exit 0;

__END__

=head1 NAME

pollQ3a.pl - Polls a Quake 3 Arena Server

=head1 SYNOPSIS

pollQ3a.pl [options]

 Options:
   -server          server address
   -port            server port
   -exec            execute command if server is available
   -help            brief help message
   -man             full documentation

=head1 OPTIONS

=over 8

=item B<-server>

Set the server address.

=item B<-port>

Set the server port.

=item B<-exec>

Execute the given command if the server is available. $server and $port will replaced with address and port.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will poll a Quake 3: Arena Server and return some status informations.
The address and port can be specified.

=cut
