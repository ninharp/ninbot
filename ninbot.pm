# ninBot Main Bot Class (c) Michael Sauer - https://github.com/ninharp/ninbot
# ninbot.pm $Id$
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
package ninbot;

use warnings;
use strict;
use Config::General qw(ParseConfig SaveConfig);
use Data::Dumper;
use Net::IRC;
use DBI;
use ninbot::mysql;
use ninbot::textdb;
use ninbot::calc;
use ninbot::users;
use ninbot::channel;
use ninbot::interpreter;

#use ninbot::partyline; # Added later

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_DEBUG}    = 2;
    $self->{_VERSION}  = "0.83.19";
    $self->{_CONFIG}   = "ninbot.conf";
    $self->{_SERVER}   = ();
    $self->{_CURSER}   = 0;
    $self->{_MUTE}     = 0;
    $self->{_CHANNELS} = {};

    # $self->{_DBH}; # General Database Handler (backend independent)
    $self->{_IRC} = new Net::IRC;

    #  $self->{_PARTYLINE} = new ninbot::partyline;
    return $self;
}

# Logs function
sub log {
    my $self    = shift;
    my $level   = shift;
    my $message = shift;
    my $date    = localtime();
    my $daemon  = 0;
    $daemon = 1 if $self->{config}->{daemon};
    $message .= "\n" if ( !$daemon );
    if ( $level <= $self->{_DEBUG} ) {

        if ( !$daemon ) {
            print $level. ") " . $message;
        }
        else {
            open( LOG, ">>ninbot.log" );
            print LOG $date . ": (" . $level . ") " . $message . "\n";
            close(LOG);
        }
    }

    #  my $partyline = $self->{_PARTYLINE};
    #print $partyline->get_Connected;
    #  my $auth = $partyline->{authorized};
    #  my @auth_users = keys %{$auth};
    #  foreach my $c (@auth_users) {
    #    print "OK User gefunden!\n";
    #    $partyline->{outbuffer}->{$c} = "(System) ".$message."\r\n";
    #  }
}

# Read Configuration
sub read_Config {
    my $self = shift;
    my $ret  = 1;

#my %config = ParseConfig(-ConfigFile => $self->{_CONFIG}, -AutoTrue => 1, -DefaultConfig => \%default_config);
    my %config = ParseConfig( -ConfigFile => $self->{_CONFIG}, -AutoTrue => 1 );
    $self->{config} = \%config;
    $self->{_DEBUG} = $config{debug} if defined $config{debug};

    # Choosing Calc Database Backend
    if ( !defined $self->{_DBH} ) {
        if ( $self->{config}->{calc_backend} =~ m/^mysql$/i ) {

            # SQL Backend
            $self->log( 2, "<Main> Using mySQL Database Backend" );
            $self->{_DBH} = new ninbot::mysql;
        }
        elsif ( $self->{config}->{calc_backend} =~ m/^textdb$/i ) {

            # Text Backend
            $self->log( 2, "<Main> Using textDB Database Backend" );
            $self->{_DBH} = new ninbot::textdb;
        }
        else {

            # Wrong or no backend! Default text backend
            $self->log( 1, "<Main> Unknown Database Backend! Falling back to 'textDB'" );
            $self->{config}->{calc_backend} = "textDB";
            $self->{_DBH} = new ninbot::textdb;
        }
    }

    #$self->{_CHANNEL} = new ninbot::channel;   # Loading Channel Module
    $self->{_USER}   = new ninbot::users;          # Loading Users Module
    $self->{_CALC}   = new ninbot::calc;           # Loading Calc Module
    $self->{_SCRIPT} = new ninbot::interpreter;    # Loading Script Module
    my %server = %{ $config{server} };
    $self->{_SERVER} = keys %server;
    my @server = $self->{_SERVER};
    $self->{_CURSER} = $server[0];
    my $t_serv = $server{ $self->{_CURSER} };
    $self->{config}->{irc_server} = $t_serv;
    undef $t_serv;

    if ( open( CHANS, "$self->{config}->{channel_file}" ) ) {
        while (<CHANS>) {
            next if $_ =~ m/^;/;
            my $key;
            my ( $channel, $topic, $flag, $comment ) = split( /;;;/, $_ );
            ( $channel, $key ) = split( /\ /, $channel ) if $channel =~ m/\s/;
            $self->{channels}->{$channel} = 1;
        }
        close(CHANS);
    }
    else {
        print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
        exit(1);
    }
    return $ret;
}

# Save Configuration
sub save_Config {
    my $self   = shift;
    my $ret    = 0;
    my $config = $self->{config};
    my %config = %$config;
    undef $config;
    $self->log( 2, "<Main> Saving Configuration." );
    $ret = 1 if SaveConfig( $self->{_CONFIG}, \%config );
    return $ret;
}

# Setup the IRC Connection
sub setup_IRC {
    my $self = shift;
    $self->read_Config;
    my $IRC = $self->{_IRC};
    $self->{conn} = $IRC->newconn(
        Nick     => $self->{config}->{irc_nickname},
        Server   => $self->{config}->{irc_server},
        Port     => $self->{config}->{irc_port},
        Username => $self->{config}->{irc_ident},
        Ircname  => $self->{config}->{irc_email}
    );
    $self->{ip} = $self->get_IP;
    $self->schedule_Save;

    #  $self->schedule_checkIP; # Nur bei dynamischen Verbindungen
    #$self->connect_DB;
    #my $pid = $self->{_PARTYLINE}->create_Server;
    #print "PID: $pid\n";
    return 1 if defined $self->{conn} || return 0;
}

sub start_IRC {
    my $self = shift;
    my $IRC  = $self->{_IRC};
    $IRC->start();
}

# Adds the handler for the IRC messages
sub setup_Handler {
    my $self = shift;
    my $conn = $self->{conn};
    if (    $conn->add_global_handler( '376', \&IRC_on_connect )
        and $conn->add_global_handler( 'disconnect', \&IRC_on_disconnect )
        and $conn->add_global_handler( '433',        \&IRC_on_nick_in_use )
        and $conn->add_global_handler( 'join',       \&IRC_on_join )
        and $conn->add_global_handler( 'part',       \&IRC_on_part )
        and $conn->add_global_handler( 'quit',       \&IRC_on_quit )
        and $conn->add_global_handler( 'nick',       \&IRC_on_nick_change )
        and $conn->add_global_handler( 'public',     \&IRC_on_public )
        and $conn->add_global_handler( 'kick',       \&IRC_on_kick )
        and $conn->add_global_handler( 'msg',        \&IRC_on_private )
        and $conn->add_global_handler( 'invite',     \&IRC_on_invite )
        and $conn->add_global_handler( 'cversion',   \&IRC_on_ctcp_version )
        and $conn->add_global_handler( 'namreply',   \&IRC_on_names_reply ) )
    {
        return 1;
    }
    else {
        return 0;
    }
    return 1;
}

# handle_Events - Handles the events
sub handle_Event {
    my ( $self, $event_type, $event ) = @_;
    my $calc     = $self->{_CALC};
    my $script   = $self->{_SCRIPT};
    my %msg_hash = %{$event};
    undef $event;
    my $message      = @{ $msg_hash{args} }[0];
    my $from_nick    = $msg_hash{nick};
    my $from         = $msg_hash{from};
    my $from_channel = $msg_hash{to}[0];
    my @calc         = $calc->get_Calc("data-event-$event_type");
    my $user         = $self->{_USER};
    my $level        = $user->check_Level($from);
    my $do_events    = "";
    $do_events = $calc[1] if defined $calc[0];
    my @c_calc = $calc->get_Calc("data-event-$from_channel-$event_type");
    my @n_calc = $calc->get_Calc("data-event-$from_nick-$event_type");
    my @n_c_calc =
      $calc->get_Calc("data-event-$from_channel-$from_nick-$event_type");
    $do_events .= " " . $c_calc[1]   if defined $c_calc[0];
    $do_events .= " " . $n_calc[1]   if defined $n_calc[0];
    $do_events .= " " . $n_c_calc[1] if defined $n_c_calc[0];

    if ( length($do_events) > 1 ) {
        my @events = split( / /, $do_events );
        foreach my $event (@events) {
            my @event_calc = $calc->get_Calc( "data-" . $event );
            if ( defined $event_calc[0] ) {
                my $event_script = $event_calc[1];
                $self->log( 3, "<Main:IRC> Running $event_type event for channel $from_channel: $event" );
                $script->parse_Script( $from_nick, $from_channel, $event_script, $level );
            }
            else {
                $self->log( 4, "<Main:IRC> Tried to run noexistent $event_type event for channel $from_channel: $event" );
            }
        }
    }
    else {
        $self->log( 5, "<Main:IRC> No $event_type events for defined!" );
    }
}

# Quits IRC
sub quit {
    my $self = shift;
    my $msg  = shift;
    my $conn = $self->{conn};
    $self->log( 1, "<Main:IRC> Quitting IRC Connection" ) if defined $conn;
    $conn->quit($msg) if defined $conn;
}

# Gets actual IP
# TODO: change to some better
sub get_IP {
    my $ipfile = "http://athena.noxa.de/~michael/ip.pl";
    my $ip     = `lynx -source $ipfile`;
    chop($ip);
    return $ip;
}

# Scheduled Saving Handler
sub schedule_Save {
    my ( $a, $b ) = @_;
    my ( $irc, $self );
    if ( !defined $b ) {
        $self = $a;
        $irc  = $self->{conn};
    }
    else {
        $irc  = $a;
        $self = $b;
    }
    $irc->schedule( $self->{config}->{save_interval}, \&schedule_Save, $self );
    $self->log( 3, "<Main> Scheduled Saving!" );
    $self->save_Config;
}

# Scheduled IP checking on dynamic IP machines
sub schedule_checkIP {
    my ( $a, $b ) = @_;
    my ( $irc, $self );
    if ( !defined $b ) {
        $self = $a;
        $irc  = $self->{conn};
    }
    else {
        $irc  = $a;
        $self = $b;
    }
    my $changed = "No";
    my $cip     = $self->{ip};
    my $nip     = $self->get_IP;
    if ( $cip ne $nip ) {
        $self->{ip} = $nip;
        $changed = "Yes [$nip]. Initiating reconnect!";
        $self->{conn}->disconnect;
        $self->{conn}->connect;
    }
    $irc->schedule( 60, \&schedule_checkIP, $self );
    $self->log( 2, "<Main> Check IP changed: $changed" );
}

# Is Channel a banned Channel
sub check_bannedChan {
    my ( $self, $chan ) = @_;
    my $ret = 0;
    foreach my $bchan ( keys %{ $self->{banlist} } ) {
        $ret = 1 if $chan eq $bchan;

        #    return 1 if $chan eq $bchan;
    }
    return $ret;
}

# Reconnect to the server when we die.
sub IRC_on_disconnect {
    my ( $irc, $event ) = @_;
    my $self = &main::get_Self;
    $self->log( 1, "<Main:IRC> Disconnected from " . $event->from() . " (" . ( $event->args() )[0] . "). Attempting to reconnect..." );
    $irc->connect();
}

# IRC Handler on connect
sub IRC_on_connect {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;
    $self->log( 1, "<Main:IRC> Connection established!" );
    if ( defined $self->{channels} ) {
        my @start_chans = keys %{ $self->{channels} };
        foreach (@start_chans) {
            $self->log( 2, "<Main:IRC> Joining $_" );
            $self->{_CHANNEL}->{$_} = ninbot::channel->new( '_NAME' => $_ );
        }
    }
    if ( $self->{config}->{irc_botmode} == 1 ) {

        # Setting Botmode (euirc.net appliance)
        $self->log( 1, "<Main:IRC> Botmode forced! Setting +B" );
        my $mynick = $self->{config}->{irc_nickname};
        $self->{conn}->sl_real( "MODE " . $mynick . " +B" );
    }
}

# IRC Handler on invite
sub IRC_on_invite {
    my $self   = &main::get_Self;
    my $irc    = shift;
    my $event  = shift;
    my $chan   = $event->{args}->[0];
    my $nick   = $event->{nick};
    my $mynick = $self->{config}->{irc_nickname};
    if ( !$self->check_bannedChan($chan) ) {
        $self->log( 2, "<Main:IRC> " . $nick . " has invited me to join " . $chan . "!\n" );
        $self->{_CHANNEL}->{$chan} = ninbot::channel->new( '_NAME' => $chan );
        $self->{conn}->privmsg( $chan, "Hallo, ich bin " . $mynick . ", ein PerlBot!" );
        $self->{conn}->privmsg( $chan, $nick . " hat mich eingeladen! Mit !part oder !ban bin ich wieder weg! Mit !hilfe gibts ne kleine Hilfe ;P" );
    }
    else {
        $self->log( 2, "<Main:IRC> " . $nick . " has invited me to banned channel " . $chan . "!\n" );
    }
}

# IRC Handler on nick in use
sub IRC_on_nick_in_use {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;
    $self->log( 1, "<Main:IRC> Nickname " . $self->{config}->{irc_nickname} . " already in use.\n" );
    my $nickname = $self->{config}->{irc_nickname};
    $nickname .= "_";
    $self->log( 1, "<Main:IRC> Trying with " . $nickname . "." );
    $irc->nick($nickname);
}

# IRC Handler on join
sub IRC_on_join {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;
    if ( defined $self->{_CHANNEL}->{ $event->{to}[0] } ) {
        $self->{_CHANNEL}->{ $event->{to}[0] }->add_name( $event->{nick} );
    }
    $self->handle_Event( "onjoin", $event )
      if $irc->{_nick} !~ m/$event->{nick}/i;

    #  print "IRC:\n".Dumper($irc)."\n\n";
    #  print "EVENT:\n".Dumper($event)."\n\n";
    $self->log( 4, "<Main:IRC> onJoin Event received from " . $event->{nick} . "." );
}

# IRC Handler on part
sub IRC_on_part {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;
    if ( $event->{nick} eq $irc->{_nick} ) {
        $self->{_CHANNEL}->{ $event->{to}[0] }->close_channel();
    }
    else {
        $self->{_CHANNEL}->{ $event->{to}[0] }->del_name( $event->{nick} );
    }
    $self->log( 4, "<Main:IRC> onPart Event received from " . $event->{nick} . "." );
}

# IRC Handler on part
sub IRC_on_quit {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;
    foreach my $chan ( keys $self->{_CHANNEL} ) {
        $self->{_CHANNEL}->{$chan}->del_name( $event->{nick} );
    }
    $self->log( 4, "<Main:IRC> onQuit Event received from " . $event->{nick} . "." );
}

# IRC Handler on nickchanges
sub IRC_on_nick_change {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;
    print Dumper($event);
    my $oldnick = $event->{nick};
    my $newnick = $event->{args}[0];
    foreach my $chan ( keys $self->{_CHANNEL} ) {
        $self->{_CHANNEL}->{$chan}->change_name( $oldnick, $newnick );
    }
    $self->log( 4, "<Main:IRC> Nickchange Event received from $oldnick->$newnick." );
}

# IRC Handler on names reply
sub IRC_on_names_reply {
    my $self  = &main::get_Self;
    my $irc   = shift;
    my $event = shift;

    #$self->{_CHANNEL}->{_NAMES};
    my $chan = $event->{args}[2];
    if ( !$self->{_CHANNEL}->{$chan} ) {
        $self->{_CHANNEL}->{$chan} = ninbot::channel->new( '_NAME' => $chan );
    }
    else {
        $self->{_CHANNEL}->{$chan}->fill_names( $event->{args}[3] );
    }

    #print @nicks;
    #print "EVENT:\n".Dumper($event)."\n\n";
    $self->log( 4, "<Main:IRC> NamesReply Event received for " . $chan . "." );
}

# IRC Handler on public/private this choose which one to choose
# fixed the problem with + and ! channels
#sub IRC_on_pubpriv {
#  my $self = &main::get_Self;
#  my $irc = shift;
#  my $msg_hash = shift;
#  my $tmp_hash = $msg_hash;
#  my %msg_hash = %{$msg_hash}; undef $msg_hash;
#  my $from_channel =$msg_hash{to}[0];
#  if ($from_channel = m/^(?:\!:\#:\+)/) {
#    $self->IRC_on_public($irc, $msg_hash);
#  }
#}

# IRC Handler on public
sub IRC_on_public {
    my $self      = &main::get_Self;
    my $calc_self = $self->{_CALC};
    my $user      = $self->{_USER};
    my $mute      = $self->{_MUTE};
    my $irc       = shift;
    my $msg_hash  = shift;
    my $tmp_hash  = $msg_hash;
    my %msg_hash  = %{$msg_hash};
    undef $msg_hash;
    my $message      = @{ $msg_hash{args} }[0];
    my $from_nick    = $msg_hash{nick};
    my $from         = $msg_hash{from};
    my $from_channel = $msg_hash{to}[0];
    my $level        = $user->check_Level($from);
    my $trigger      = $self->{config}->{command_trigger};
    my $conn         = $self->{conn};

    #  if ($message =~ m/^(calc|match|${trigger}index|${trigger}list)/i) {
    if ( $message =~ m/^(data|match|${trigger}index|${trigger}list)/i ) {
        $calc_self->Handler( $from, $from_nick, $from_channel, $message );
    }
    elsif ( $message =~ m/^${trigger}op$/i ) {
        if ( $user->is_Active($from) ) {
            $conn->mode( $from_channel . " +o " . $from_nick );
            $self->log( 3, "<Main:IRC:pub> Opping " . $from_nick . " on channel " . $from_channel );
        }
    }
    elsif ( $message =~ m/^${trigger}ban$/i ) {
        if ( defined $self->{_CHANNEL}->{$from_channel} ) {
            if ( !$self->{_CHANNEL}->{$from_channel}->is_PermChan($from_channel)
              )
            {
                $self->{banlist}->{$from_channel} = 1;
                $conn->privmsg( $from_channel, "OK, " . $from_nick . ", weg bin ich! Und ich komm auch nicht wieder! cu" );
                $conn->part($from_channel);
                $self->log( 2, "<Main:IRC:pub> Requested to ban " . $from_channel . " by " . $from_nick );
            }
            else {
                $conn->privmsg( $from_channel, $from_nick . ", ich geh nicht!" );
            }
        }
        else {
            $self->log( 2, "<Main:IRC:pub> Requested to ban " . $from_channel . " but it is not in Channel list" );
        }
    }
    elsif ( $message =~ m/^${trigger}part$/i ) {
        if ( !$self->{_CHANNEL}->{$from_channel}->is_PermChan($from_channel) ) {
            $conn->privmsg( $from_channel, "OK, " . $from_nick . ", weg bin ich! cu" );
            $conn->part($from_channel);
            $self->log( 2, "<Main:IRC:pub> Requested Parting from " . $from_channel . " by " . $from_nick );
        }
        else {
            $conn->privmsg( $from_channel, $from_nick . ", ich geh nicht!" );
        }
    }
    elsif ( $message =~ m/^${trigger}join\ (.*)/i ) {
        my $join_chan = $1;
        if ( $level >= 4 ) {

            #print Dumper($self);
            if ( !$self->check_bannedChan($join_chan) ) {
                $self->log( 2, "<Main:IRC:pub> Requested Join Public Chan " . $join_chan . " from " . $from_nick . " on " . $from_channel );
                $self->{_CHANNEL}->{$join_chan} = ninbot::channel->new( '_NAME' => $join_chan );
            }
            else {
                $self->log( 2, "<Main:IRC:pub> Channel " . $join_chan . " is banned!" );
            }
        }
    }
    elsif ( $message =~ m/^${trigger}mute$/i ) {
        if ( $self->{_CHANNEL}->{$from_channel}->isMuted() == 0 ) {
            $self->log( 2, "<Main:IRC:pub> Request from $from_nick to be mute in $from_channel for 2 minutes!" );
            $self->{_CHANNEL}->{$from_channel}->mute();
            $conn->privmsg( $from_channel, "Ich bin hier nun 2 Minuten lautlos!" );
            my $unmute_script = sub {
                my ( $conn, $chan ) = @_;
                my $self = &main::get_Self;
                $self->log( 2, "<Main:IRC:pub> Unmuting $chan" );
                if ( $self->{_CHANNEL}->{$chan}->isMuted() == 1 ) {
                    $self->{_CHANNEL}->{$chan}->unMute();
                }
            };
            $conn->schedule( 2 * 60, $unmute_script, $from_channel );
        }
        else {
            $self->log( 3, "<Main:IRC:pub> Dont progress !mute... im already muted!" );
        }
    }
    elsif ( $message =~ m/^${trigger}timer\ (\d*)\ (.*)/i ) {
        my $zeit         = $1 * 60;
        my $what         = $2;
        my $timer_script = sub {
            my ( $conn, $chan, $nick, $what ) = @_;
            $conn->privmsg( $chan, "Ey " . $nick . " dein " . $what . " ist fällig!!!" );
            $conn->privmsg( $nick, "Dein " . $what . " ist fällig!!! Nur das du's weisst!" );
        };
        $self->log( 3, "<Main:IRC:pub> Timer " . ( $zeit / 60 ) . " min ($zeit sec) $what $from $from_nick on $from_channel!" );
        $conn->privmsg( $from_channel, "OK, $from_nick, $what ist in ". ( $zeit / 60 ) . " Minute(n) fällig!" );
        $conn->schedule( $zeit, $timer_script, $from_channel, $from_nick, $what );
    }
    elsif ( $message =~ m/^${trigger}eval\W+(.*)/i ) {
        if ( $self->{_CHANNEL}->{$from_channel}->isMuted() == 0 ) {
            $self->{_SCRIPT}->{command} = "eval";
            $self->{_SCRIPT}->parse_Script( $from_nick, $from_channel, $1, $level );
        }
        else {
            $self->log( 3, "<Main:IRC:pub> Dont progress !eval... im muted!" );
        }
    }
    elsif ( $message =~ m/^$trigger(.*?)$/i ) {
        if ( $self->{_CHANNEL}->{$from_channel}->isMuted() == 0 ) {
            $message =~ m/^.(.*)$/;
            my $command = $1;
            my $param   = "";
            if ( $command =~ m/\ / ) {
                $command =~ m/(.*?)\ (.*$)/;
                $command = $1;
                $param   = $2;
            }
            $self->log( 3, "<Main:IRC:pub> Searching Script for Command '$command' [$param]" );
            my @calc = $calc_self->get_Calc( "com-" . $command );
            if ( defined $calc[1] ) {

                # name;;;value;;;author;;;time;;;changed;;;mode;;;flag;;;level
                my (
                    $calc_name,    $calc_text, $calc_nick, $calc_date,
                    $calc_changed, $calc_mode, $calc_flag, $calc_level
                ) = @calc;
                $self->log( 4, "<Main:IRC:pub> Found Calc Command for '$command'" );
                if ( $calc_text =~ m/\{(.*)\}/i ) {
                    my $script = $1;
                    if ( $level >= $calc_level ) {
                        $self->{_SCRIPT}->{command} = $command;
                        $self->{_SCRIPT}->parse_Script( $from_nick, $from_channel, $script, $level, $param );
                    }
                    else {
                        $self->log( 3, "<Main:IRC:pub> User $from_nick level ($level) is not high enough for that calc ($calc_level)!" );
                    }
                }
                elsif ( $calc_text =~ m/^handler\((.*?)\)$/i ) {
                    my $handler = $1;
                    $self->log( 4, "<Main:IRC:pub> Entering Handler $handler from Calc!" );
                    my $HDL = $self->{ "_" . uc($handler) };
                    $param = " " . $param if $param ne "";
					#$HDL->Handler($from_nick, $from_channel, $self->{config}->{command_trigger}.$command.$param);
                }
                elsif ( $calc_text =~ m/^\!\!(.*)/i ) {
                    my $link = $1;
                    $self->log( 4, "<Main:IRC:pub> Symbolic link entry from Calc $calc_name to $link" );
                    $self->{_SCRIPT}->{command} = $command;
                    if ( $link =~ m/^com-/i ) {
                        my @link_calc = $calc_self->get_Calc($link);
                        my ( $link_name, $link_script, undef, undef, undef, undef, undef, undef ) = @link_calc;
                        if ( $link_script =~ m/\{(.*)\}/i ) {
                            my $link_script = $1;
                            if ( $level >= $link_calc[7] ) {
                                $self->{_SCRIPT}->parse_Script( $from_nick, $from_channel, $link_script, $level, $param );
                            }
                        }
                    }
                    else {
                        $calc_self->Handler( $from, $from_nick, $from_channel, "data " . $link );
                    }
                }
                else {
                    $self->{conn}->privmsg( $from_channel, $calc_text );
                }
            }
        }
        else {
            $self->log( 3, "<Main:IRC:pub> Dont progress !command... im muted!" );
        }
    }
    else {
        # normal messages
    }
}

# IRC Handler on private
sub IRC_on_private {
    my $self         = &main::get_Self;
    my $calc_self    = $self->{_CALC};
    my $irc          = shift;
    my $msg_hash     = shift;
    my $user         = $self->{_USER};
    my %msg_hash     = %{$msg_hash};
    my $command      = @{ $msg_hash{args} }[0];
    my $from_nick    = $msg_hash{nick};
    my $from_channel = @{ $msg_hash{to} }[0];
    my $from         = $msg_hash{from};
    my $level        = $user->check_Level($from);
    my $trigger      = $self->{config}->{command_trigger};
    if ( $from_channel =~ m/^(?:\!|\+)/ ) {

        #    $self->log(3, "Main Routine: Id or nonMode Channel");
        &IRC_on_public( $self->{_IRC}, $msg_hash );
    }
    else {
        if ( $command =~ m/^join\ (.*)/i ) {
            if ( $level >= 4 ) {
                $self->log( 3, "<Main:IRC:priv> PrivCmd Join $1 from $from_nick" );
                $self->{_CHANNEL}->{$1} = ninbot::channel->new( '_NAME' => $1 );
            }
            else {
                $irc->privmsg( $from_nick,
                    "Du darfst das nicht mit Level $level!" );
                $self->log( 3,
                    "<Main:IRC:priv> Denied PrivCmd Join $1 from $from_nick" );
            }
        }
        elsif ( $command =~ m/^part\ (.*)/i ) {
            $self->log( 3, "<Main:IRC:priv> PrivCmd Parting $1 from $from_nick" );
            $irc->part($1) if !$self->{_CHANNEL}->is_PermChan($1);
        }
        elsif ( $command =~ m/^adduser (.*?) (\d*)/i ) {
            my $add_nick = $1;
            my $add_host = $user->get_Host($add_nick) || "nix";
            my $add_flag = $2;
            if ( $user->check_User($from) >= 10 ) {
                $self->log( 2, "<Main:IRC:priv> Adding User $add_nick ($add_host) with level $add_flag by $from_nick" );
            }
        }
        elsif ( $command =~ m/^id\ (.*)/i ) {
            $self->log( 3, "<Main:IRC:priv> Id from $from_nick" );
            if ( !$user->is_Active($from) ) {
                if ( $user->active_User( $from, $1 ) ) {
                    $self->log( 3, "<Main:IRC:priv> User $from_nick was succesfully identified!" );
                    $irc->privmsg( $from_nick, "Du bist erfolgreich identifiziert worden!" );
                }
                else {
                    $self->log( 3, "<Main:IRC:priv> User $from_nick failed id!" );
                }
            }
            else {
                $self->log( 3,
                    "<Main:IRC:priv> User $from_nick already identified!" );
                $irc->privmsg( $from_nick, "Du bist schon erfolgreich identifiziert worden!" );
            }
        }

#  elsif ($command =~ m/^partyline$/i) {
#    my @sip = split(/\./,"192.168.100.1");
#    my $n = 256;
#    my $fip = ($sip[0]*($n * $n * $n))+($sip[1]*($n * $n))+($sip[2] * $n) + ($sip[3]);
#    $self->{conn}->sl("PRIVMSG $from_nick :\001DCC CHAT chat $fip 3333\001");
#    $self->{conn}->sl("PRIVMSG $from_nick :\001DCC CHAT chat $fip 3333\001");
#    print "partyline juhuuu!\n";
#    #    DCC type argument address port [size]
#  }
        elsif ( $command =~ m/^pass\ (.*)/i ) {
            my $password = crypt( $1, $from_nick );
            if ( $user->check_User($from) == 0 ) {
                my $sth =
                  $self->{_DBH}->update( "user",
                    { "handle", $from_nick, "password", $password } )
                  ; #prepare("UPDATE user SET password='$password' WHERE handle = '$from_nick'");
                $sth->execute;
                $self->log( 3, "<Main:IRC:priv> Setting password for $from_nick" );
            }
            else {
                $self->log( 3, "<Main:IRC:priv> Denied Password Set for $from_nick" );
            }
        }
        elsif ( $command =~ m/^kill\s+((.*))?/i ) {
            my $kill_msg = $1;
            if ( $user->check_User($from) >= 10 ) {
                $self->log( 3, "<Main:IRC:priv> Kill requested by $from_nick ($kill_msg)" );
                $self->{conn}->quit("Kill requested by $from_nick ($kill_msg)")
                  if defined $kill_msg;
                $self->{conn}->quit("Kill requested by $from_nick")
                  if defined !$kill_msg;
                $self->save_Config;
                exit(1);
            }
        }
        elsif ( $command =~ m/^nick\ (.*)/i ) {
            my $new_nick = $1;
            if ( $user->check_User($from) >= 5 ) {
                $self->log( 3, "<Main:IRC:priv> Nickchange to $new_nick requested by $from_nick" );
                $self->{conn}->sl( "NICK " . $new_nick );

            }
        }
        elsif ( $command =~ m/^save/i ) {
            $self->log( 3, "<Main:IRC:priv> Saving Configuration from $from_nick" );
            $self->save_Config;
        }
        elsif ( $command =~ m/^load/i ) {
            $self->log( 3, "<Main:IRC:priv> Loading Configuration from $from_nick" );
            $self->read_Config;
        }
        elsif ( $command =~ m/^unban\ (.*)/i ) {
            $self->log( 3, "<Main:IRC:priv> Unbanning $1 by $from_nick" );
            if ( $user->check_User($from) >= 5 ) {
                delete $self->{banlist}->{$1};
                $self->{conn}->privmsg( $from_nick, "OK, $1 ist nun nichtmehr gebannt!" );
            }
            else {
                $self->{conn}->privmsg( $from_nick, "Tut mir leid! Aber du darfst das nicht!" );
            }
        }
        else {
            $self->log( 2, "<Main:IRC:priv> Message from $from_nick -> $command!" );
        }
    }
}

# IRC Handler on ctcp version
sub IRC_on_ctcp_version {
    my $self     = &main::get_Self;
    my $irc      = shift;
    my $msg_hash = shift;
    my %msg_hash = %{$msg_hash};
    undef $msg_hash;
    my $from_nick = $msg_hash{nick};
    $self->log( 3, "<Main:IRC> CTCP VERSION from " . $from_nick );
    $self->{conn}->notice( $from_nick, "VERSION ninbot v" . $self->{_VERSION} . " (c) ninharp <ninharp\@gmx.net>" );
}

# IRC Handler on kick
sub IRC_on_kick {
    my $self     = &main::get_Self;
    my $irc      = shift;
    my $msg_hash = shift;
    my %msg_hash = %{$msg_hash};
    undef $msg_hash;
    my @kicked_users = @{ $msg_hash{to} };
    my $from_channel = @{ $msg_hash{args} }[0];
    my $kicked       = 0;
    foreach my $user (@kicked_users) {

        if ( $user eq $self->{config}->{irc_nickname} ) {
            $self->log( 1, "<Main:IRC> I was kicked from " . $from_channel );
            $self->{conn}->join($from_channel);
            $self->{conn}->privmsg( $from_channel, "Das nächste mal gehts auch freundlicher! *beleidigtsei*" );
            $self->{conn}->part($from_channel);
        }
    }
}

1;
