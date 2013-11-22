#!/usr/bin/perl -w
# ninBot Main Class (c) Michael Sauer - https://github.com/ninharp/ninbot
# bot.pl $Id$
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option) any
# later version
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
# the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc., 59
# Temple Place, Suite 330, Boston, MA 02111-1307 USA
#



use strict;
use ninbot;

$| = 1;

### Create new ninbot Object

my $bot = ninbot->new();

### Variables

my $pwd = `pwd`;
chop($pwd);
my %config = ();

### Signal Management Routines
# Sets the Signal Handler
$SIG{INT}  = \&sig_quit_Bot;
$SIG{TERM} = \&sig_quit_Bot;
$SIG{KILL} = \&sig_quit_Bot;
$SIG{HUP}  = \&sig_rehash_Bot;

sub sig_rehash_Bot {
    $bot->read_Config();
    my $temp = $bot->{config};
    %config = %$temp;
}

sub sig_quit_Bot {
    my $signal = shift;
    $bot->save_Config;
    $bot->quit("Caught Signal: $signal");
    &remove_Pid if $config{daemon};
    exit(0);
}

### Routines

sub write_Pid {
    my $pid = shift;
    $bot->log( 1, "<Bot> PID = $pid" );
    open( PID, ">$config{pid_file}" );
    print PID $pid;
    close(PID);
}

sub remove_Pid {
    $bot->log( 1, "<Bot> Removing PID File" );
    system( "rm", $config{pid_file} );
}

sub get_Self {
    return $bot;
}

sub read_Config {
    my $ret = 0;
    $ret = 1 if $bot->read_Config();
    my $temp = $bot->{config};
    %config = %$temp;
    return $ret;
}

### Main

# chroot($pwd) or die "Couldn't chroot to $pwd: $!"; # Not now!

$bot->log( 0, "<Bot> *** IRC ninBot v" . $bot->{_VERSION} . " ***\n" );

$bot->log( 0, "<Bot> Reading out configuration..\n" );
&read_Config();
$bot->log( 0, "<Bot> Set Debuglevel to " . chop( $config{debug} ) . "\n" )
  if defined $config{debug};
$bot->log( 0, "<Bot> Setting up IRC Connection..\n" );
$bot->setup_IRC();
$bot->log( 0,
    "<Bot> - Using IRC Nickname:\t\t" . $config{irc_nickname} . "\n" );
$bot->log( 0, "<Bot> - Using IRC Server:\t\t" . $config{irc_server} . "\n" );
my %server = %{ $config{server} };

foreach ( keys %server ) {
    $bot->log( 0, "<Bot> Server $_ = $server{$_}\n" );
}

$bot->log( 0, "<Bot> Setting up IRC Handler..\n" );
$bot->setup_Handler();
if ( $config{daemon} ) {
    $bot->log( 0, "<Bot> Forking Bot..\n" );
    my $pid = fork;
    print "PID=$pid\n";
    &write_Pid($pid) if $pid != 0;
    exit if $pid;
    die "<Bot> Couldn't fork: $!" unless defined $pid;
}
$bot->log( 1, "<Bot> Starting IRC Connection.." );
$bot->start_IRC();
