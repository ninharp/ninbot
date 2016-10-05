# ninBot Main Bot Class (c) Michael Sauer - https://github.com/ninharp/ninbot
# ninBot.pm $Id$
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
package ninBot::IRC::Bot;

use Bot::BasicBot;
use strict;
use warnings::register;
use base 'Bot::BasicBot';
use ninBot::IRC::Channel;

sub new {
  my $class = shift;
  my $main = shift;
  #TODO implement Alternate Nicks, Flood protection, ...
  my $self = bless Bot::BasicBot->new( 
  						#channels    => [ "#test" ],
    					nick 		=> $main->{config}->{irc_nickname},
                        server 		=> $main->{config}->{irc_server},
                        port		=> $main->{config}->{irc_port},
                        username	=> $main->{config}->{irc_ident},
                        name		=> $main->{config}->{irc_email},
                        #TODO Fix localaddr & ipv6
                        #localaddr	=> $main->{config}->{irc_hostname},
                        ssl			=> $main->{config}->{irc_ssl},
                        no_run		=> 1
                        ), $class;
                        
  $self->{_MAIN} = $main;
  $self->{_CLASS} = $class;
                   
  $main->log( 2, "<".$class."> Created IRC Bot instance!" );
  bless $self, $class;
  return $self;
}

sub connected {
  my $irc = shift;
  my $class = $irc->{_CLASS};
  my $self  = $irc->{_MAIN};# &main::get_Self;
  $self->log( 1, "<".$class."> Connection established!" );
  if ( $self->{config}->{irc_botmode} == 1 ) {
        # Setting Botmode (euirc.net appliance)
        $self->log( 1, "<".$class."> Botmode forced! Setting +B-x" );
        my $mynick = $self->{config}->{irc_nickname};
        
        $irc->{IRCOBJ}->{socket}->put( "MODE " . $mynick . " +B" );
		$irc->{IRCOBJ}->{socket}->put( "MODE " . $mynick . " -x" );
        #$self->{conn}->sl_real( "MODE " . $mynick . " +B" );
		#$self->{conn}->sl_real( "MODE " . $mynick . " -x" );
  }
  $irc->{IRCOBJ}->{socket}->put("vhost btc btc\r\n");
  if ( defined $self->{channels} ) {
    my @start_chans = keys %{ $self->{channels} };
    foreach (@start_chans) {
        $self->log( 2, "<".$class."> Joining $_" );
    	$self->{_CHANNEL}->{$_} = ninBot::IRC::Channel->new( '_NAME' => $_ );
  	}
  }
  $self->log( 1, "<".$class."> Connected as ".$irc->nick." to ".$irc->server );
}

sub said {
	my $irc       	= shift;
	my $mess 		= shift;
	my $class 		= $irc->{_CLASS};
  	my $self  		= $irc->{_MAIN};# &main::get_Self;
    my $calc 		= $self->{_CALC};
    my $user      	= $self->{_USER};
    my $mute      	= $self->{_MUTE};
    my $stats	  	= $self->{_STATS};
    
	my $message 		= $mess->{body};
	my $from_nick		= $mess->{who};
	my $from			= $mess->{raw_nick};
	my $from_channel 	= $mess->{channel};
	my $level			= 0;
	my $trigger      	= $self->{config}->{command_trigger};
	
    
    if ( $message =~ m/^(calc|match|${trigger}index|${trigger}list)/i ) {
        $calc->Handler( $from, $from_nick, $from_channel, $message );
    }
    elsif ( $message =~ m/^${trigger}op$/i ) {
		$stats->inc_name("com-op");
        if ( $user->is_Active($from) ) {
        	$irc->{IRCOBJ}->{socket}->put( "MODE " . $from_channel . " +o " . $from_nick );
            $self->log( 3, "<".$class."::said> Opping " . $from_nick . " on channel " . $from_channel );
        }
    }
    elsif ( $message =~ m/^${trigger}ban$/i ) {
		$stats->inc_name("com-ban");
        if ( defined $self->{_CHANNEL}->{$from_channel} ) {
            if ( !$self->{_CHANNEL}->{$from_channel}->is_PermChan($from_channel)
              )
            {
                $self->{banlist}->{$from_channel} = 1;
                $irc->say(channel => $mess->{channel}, body => "OK, " . $from_nick . ", weg bin ich! Und ich komm auch nicht wieder! cu");
                $irc->part($from_channel);
                $self->log( 2, "<".$class."::said> Requested to ban " . $from_channel . " by " . $from_nick );
            }
            else {
            	$irc->say(channel => $mess->{channel}, body => $from_nick . ", ich geh nicht!");
            }
        }
        else {
            $self->log( 2, "<".$class."::said> Requested to ban " . $from_channel . " but it is not in Channel list" );
        }
    }
    elsif ( $message =~ m/^${trigger}part$/i ) {
		$stats->inc_name("com-part");
        if ( !$self->{_CHANNEL}->{$from_channel}->is_PermChan($from_channel) ) {
        	$irc->say(channel => $mess->{channel}, body => "OK, " . $from_nick . ", weg bin ich! cu" );
            $irc->part($from_channel);
            $self->log( 2, "<".$class."::said> Requested Parting from " . $from_channel . " by " . $from_nick );
        }
        else {
        	$irc->say(channel => $mess->{channel}, body => $from_nick . ", ich geh nicht!" );
        }
    }
    elsif ( $message =~ m/^${trigger}join\ (.*)/i ) {
		$stats->inc_name("com-join");
        my $join_chan = $1;
        $level = $user->check_Level($from);
        if ( $level >= 4 ) {

            #print Dumper($self);
            if ( !$self->check_bannedChan($join_chan) ) {
                $self->log( 2, "<".$class."::said> Requested Join Public Chan " . $join_chan . " from " . $from_nick . " on " . $from_channel );
                $self->{_CHANNEL}->{$join_chan} = ninbot::channel->new( '_NAME' => $join_chan );
            }
            else {
                $self->log( 2, "<".$class."::said> Channel " . $join_chan . " is banned!" );
            }
        }
    }
    # TODO: Add parameter to mute command
    elsif ( $message =~ m/^${trigger}mute$/i ) {
		$stats->inc_name("com-mute");
        if ( $self->{_CHANNEL}->{$from_channel}->isMuted() == 0 ) {
            $self->log( 2, "<".$class."::said> Request from $from_nick to be mute in $from_channel for 2 minutes!" );
            $self->{_CHANNEL}->{$from_channel}->mute();
            $irc->say(channel => $mess->{channel}, body => "Ich bin hier nun 2 Minuten lautlos!" );
            my $unmute_script = sub {
                my ( $conn, $chan ) = @_;
                my $self = &main::get_Self;
                $self->log( 2, "<".$class."::said> Unmuting $chan" );
                if ( $self->{_CHANNEL}->{$chan}->isMuted() == 1 ) {
                    $self->{_CHANNEL}->{$chan}->unMute();
                }
            };
            #TODO schedule unmuting
            #$conn->schedule( 2 * 60, $unmute_script, $from_channel );
        }
        else {
            $self->log( 3, "<".$class."::said> Dont progress !mute... im already muted!" );
        }
    }
    elsif ( $message =~ m/^${trigger}timer\ (\d*)\ (.*)/i ) {
		$stats->inc_name("com-timer");
        my $zeit         = $1 * 60;
        my $what         = $2;
        my $timer_script = sub {
            my ( $conn, $chan, $nick, $text, $what ) = @_;
            $irc->say(channel => $mess->{channel}, body => $nick . ": " . $text . ": ". $what );
        };
 
        $self->log( 3, "<".$class."::said> Timer " . ( $zeit / 60 ) . " min ($zeit sec) $what $from $from_nick on $from_channel!" );
        $irc->say(channel => $mess->{channel}, body => "OK, $from_nick ich gebe dir in ". ( $zeit / 60 ) . " Minute(n) bescheid!" );
        #TODO schedule timer script
        #$conn->schedule( $zeit, $timer_script, $from_channel, $from_nick, "Jetzt ist fertig", $what );
        #if ($zeit > 60) {
		#	$conn->schedule( $zeit-60, $timer_script, $from_channel, $from_nick, "Bald ist fertig", $what );
		#}
    }
    elsif ( $message =~ m/^${trigger}eval\W+(.*)/i ) {
		$stats->inc_name("com-eval");
	#print $from_channel."\n\n".Dumper($self->{_CHANNEL})."\n\n";
        if ( $self->{_CHANNEL}->{$from_channel}->isMuted() == 0 ) {
            $level = $user->check_Level($from);
            $self->{_SCRIPT}->{command} = "eval";
            $self->{_SCRIPT}->parse_Script( $from_nick, $from_channel, $1, $level );
        }
        else {
            $self->log( 3, "<".$class."::said> Dont progress !eval... im muted!" );
        }
    }
    elsif ( $message =~ m/^$trigger(.*?)$/i ) {
    	print "Normal trigger\n";
        $level = $user->check_Level($from);
		if ( !defined $self->{_CHANNEL}->{$from_channel}) {
			$self->{_CHANNEL}->{$from_channel} = ninBot::IRC::Channel->new( '_NAME' => $from_channel );
		}
        if ( $self->{_CHANNEL}->{$from_channel}->isMuted() == 0 ) {
            $message =~ m/^.(.*)$/;
            my $command = $1;
            my $param   = "";
            if ( $command =~ m/\ / ) {
                $command =~ m/(.*?)\ (.*$)/;
                $command = $1;
                $param   = $2;
            }
            $self->log( 3, "<".$class."::said> Searching Script for Command '$command' [$param]" );
            my @calc = $calc->get_Calc( "com-" . $command );
            if ( defined $calc[2] ) {
				$stats->inc_name("_TRIGGER");
				$stats->inc_name("com-$command");
                my ( $calc_name, $calc_text, $calc_nick, $calc_date, $calc_changed, $calc_flag, $calc_level ) = @calc;
                $calc_level = 0 if (!defined $calc_level);
                $self->log( 4, "<".$class."::said> Found Calc Command for '$command'" );
                if ( $calc_text =~ m/\{(.*)\}/i ) {
                    my $script = $1;
                    if ( $level >= $calc_level ) {
                        $self->{_SCRIPT}->{command} = $command;
                        $self->{_SCRIPT}->parse_Script( $from_nick, $from_channel, $script, $level, $param );
                    }
                    else {
                        $self->log( 3, "<".$class."::said> User $from_nick level ($level) is not high enough for that calc $calc_level)!" );
                    }
                }
                elsif ( $calc_text =~ m/^handler\((.*?)\)$/i ) {
                    my $handler = $1;
					foreach my $plugin (@{$self->{_PLUGINS}}) {
						if ($plugin eq $handler) {
							$self->log( 4, "<".$class."::said> Entering Handler $handler from Calc!" );
							my $plugin_ret = $plugin->Handler($command, $param);
							$irc->say(channel => $mess->{channel}, body => $plugin_ret );
							$self->{conn}->privmsg( $from_channel, $plugin_ret );
						}
					}
                }
                elsif ( $calc_text =~ m/^\!\!(.*)/i ) {
                    my $link = $1;
                    $self->log( 4, "<".$class."::said> Symbolic link entry from Calc $calc_name to $link" );
                    $self->{_SCRIPT}->{command} = $command;
                    $link = "com-".$link if ($link !~ m/^com-/i);
                    if ( $link =~ m/^com-/i ) {
                        my @link_calc = $calc->get_Calc($link);
                        my ( $nr, $link_name, $link_script, undef, undef, undef, undef, undef ) = @link_calc;
                        if ( $link_script =~ m/\{(.*)\}/i ) {
                            my $link_script = $1;
                            if ( $level >= $link_calc[7] and $link_calc[6] =~ /r/ ) {
                                $self->{_SCRIPT}->parse_Script( $from_nick, $from_channel, $link_script, $level, $param );
                            }
                        }
                    }
                    else {
                        $calc->Handler( $from, $from_nick, $from_channel, "data " . $link );
                    }
                }
                else {
                	$irc->say(channel => $mess->{channel}, body => $calc_text );
                }
            }
        }
        else {
            $self->log( 3, "<".$class."::said> Dont progress !command... im muted!" );
        }
    }
    else {
    	# TODO Log normal messages to pisg conform log file (stats module?)!?
        # normal messages
    }
    
    return "";
}

1;