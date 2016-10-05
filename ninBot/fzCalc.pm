# Main Calc Module for ninBOT - https://github.com/ninharp/ninbot
# calc.pm $Id$
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
package ninBot::fzCalc;

use Data::Dumper;
use POSIX qw(strftime);

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT} = &main::get_Self;
    $self->{_DBH} = $self->{_BOT}->{_DBH}; # allgemeiner dbh hier rein für allgmeeine funcs für text und sql
    $self->{_BOT}->log( 3, "<fzCalc> Initialized..." );
    return $self;
}

# Get a calc by name
sub get_Calc {
    my ( $calc_self, $calc ) = @_;
    my $dbh = $calc_self->{_DBH};
    my @ret;
    if ( defined $calc ) {
        $calc =~ s/\'/\\\'/gi;

		# Returns an array with all entries from column $3 that are like $2 from database $1
        @ret = $dbh->select( "calc", "^" . $calc . "\$", 3 );
    }
    return @ret;
}

# Gets a random calc
sub rand_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 0;
    my $field	  = 3;
    my $not		  = 0;
    my $filter	  = "^command/.*";
    my $dbh       = $calc_self->{_DBH};
    my @entry 	  = $dbh->random( "calc", ";;;", $field, $not, $filter );
    my @ret = split( /;;;/, $entry[0] );
    return @ret;
}

# Gets a random command calc
sub rand_com_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 0;
    my $field	  = 1;
    my $not		  = 1;
    my $filter	  = "^command/dope/.*";
    my $dbh       = $calc_self->{_DBH};
    my @entry 	  = $dbh->random( "calc", ";;;", $field, $not, $filter );
    my @ret = split( /;;;/, $entry[0] );
    return @ret;
}

# Deletes a calc
sub del_Calc {
    my ( $calc_self, $name ) = @_;
    my $self = &main::get_Self;
    my $dbh  = $calc_self->{_DBH};
    my $ret  = 0;
    if ( defined $name ) {
        $ret = $dbh->del( "calc", $name );
    }
    return $ret;
}

# Matches calcs by match string
sub match_Calc {
    my ( $calc_self, $match_string ) = @_;
    $match_string =~ s/\*/\.\*/g;
    $match_string =~ s/\'/\\\'/g;
    $match_string = "(^com-)?" . $match_string;
    my @ret;
    my $dbh = $calc_self->{_DBH};
    my @found = $dbh->match( "calc", $match_string );
    foreach $entry (@found) {
        my @row = split( /;;;/, $entry );
        my ( $nr, $name, $text, $author, $date, $changed, $flag, $level ) = @row;
        if ( $name =~ m/^com-/i ) {
            push( @ret, "!" . substr( $name, 4, length( $name ) ) );
        }
        elsif ( $name !~ m/^data-/i ) {
            push( @ret, $name );
        }
    }
    return @ret;
}

# lists com-* commands
sub list_Com {
    my $calc_self = shift;
    my @ret;
    my $dbh         = $calc_self->{_DBH};
    my $bot         = $calc_self->{_BOT};
    my @com_entries = $dbh->match( "calc", "^command/dope/" );
    foreach $entry (@com_entries) {
        my @row = split( /;;;/, $entry );
        my $command = $row[1];
        $command =~ s/^com-/$bot->{config}->{command_trigger}/i;
        push( @ret, $command );
    }
    return @ret;
}

# Calc Handler for public calcs
sub Handler {
    my $calc_self    = shift;
    my $self         = $calc_self->{_BOT};
    my $stats		 = $self->{_STATS};
    my $from         = shift;
    my $from_nick    = shift;
    my $from_channel = shift;
    my $message      = shift;
    my $irc          = $self->{_IRC};
    my $user         = $self->{_USER};
    my $trigger      = $self->{config}->{command_trigger};
    my $level        = $user->check_Level($from);

    # Crypting Routine

    #
    # Random Calc
    if ( $message =~ m/^calc$/i ) {
		$stats->inc_name("com-data");
        my @calc = $calc_self->rand_Calc;
        my $nr = $calc[0];
        my $auth = $calc[1];
        my $author = $calc[2];
        my $name = $calc[3];
        my $value = $calc[4];
        my $date = $calc[5];
        my $changed = $calc[6];
        my $flag = $calc[11];
        my $clevel = $calc[7];
        my ($network, $count, $tag, $lastcall, $channel) = 0;
        if ( defined $name ) {
            while ($level <= $clevel) {
                @calc = $calc_self->rand_Calc;
				$name = $calc[3];
				$value = $calc[4];
				$author = $calc[2];
				$date = $calc[5];
				$changed = $calc[6];
				$flag = $calc[11];
				$clevel = $calc[7];
            }
            ( $nr, $auth, $author, $name, $value, $date, $changed, $clevel, $channel, $network, $count, $flag, $tag, $lastcall ) = @calc;
            
    		my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime($date);
            # [bromium, 2016-09-26 12:43:41 in #drogen #18]
            $irc->say(channel =>  $from_channel, body => "* " . $name . " = " . $value . " [" . $author . ", " . $now_string . " in ". $channel . "]");
        }
        else {
            $irc->say(channel =>  $from_channel, body => "* Sorry but the database is still empty ;(" );
        }
        $self->log( 3, "<fzCalc> Random entry from $from_nick($level) on $from_channel!" );
    }

    # Get Calc
    elsif ( $message =~ m/^calc\ (.*)$/i ) {
		$stats->inc_name("com-dataget");
        my $calc_name = $1;
        if ( $calc_name !~ m/^\W*$/i ) {
            my @calc = $calc_self->get_Calc($calc_name);
            my $author = $calc[2];
			my $name = $calc[3];
			my $value = $calc[4];
			my $date = $calc[5];
			my $changed = $calc[6];
			my $clevel = $calc[7];
			my $channel = $calc[8];
			my $network = $calc[9];
			my $count = $calc[10];
			my $flag = $calc[11];
			
            if ( !defined $name ) {
                $irc->say(channel =>  $from_channel, body => "Kein Calc fuer '$calc_name'" );
            }
            else {
                if ( $author eq $from_nick and $level >= $clevel or $level == 10 ) {
                    if ( length( $calc[4] ) >= 395 ) {
                        $value = substr( $value, 0, 395 ) . "...";
                    }
                    $irc->say(channel =>  $from_channel, body => "* ".$name." = ".$value." [" . $author . ", " . $date . " in ". $channel . "]" );
                }
                else {
                    $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' ist privat!" );
                }
            }
            $self->log( 3, "<fzCalc> Requesting entry $calc_name from $from_nick($level) on $from_channel!");
        }
    }

    elsif ($message =~ m/^${trigger}(?:index|list)\W?(\d*)/i or $message =~ m/^${trigger}list\W?(\d*)/i ) {
		$stats->inc_name("com-index");
        my @com_list = $calc_self->list_Com;
        my $cur_page = $1 || 1;
        my $max_page = int( scalar(@com_list) / 20 );
        $max_page = 1         if $max_page == 0;
        $cur_page = $max_page if $cur_page > $max_page;
        my $commands;
        my $start_com = ( $cur_page * 20 ) - 20;
        my $end_com   = $start_com + 20;
        $end_com = scalar(@com_list) if $end_com > scalar(@com_list);

        for ( my $i = $start_com ; $i < $end_com ; $i++ ) {
            $commands .= $com_list[$i];
            $commands .= ", "
              if ( $i + 1 ) < $end_com and defined $com_list[ $i + 1 ];
        }
        
        $irc->say(channel => $from_channel, body => $from_nick . ": Auf Seite " . $cur_page . "/" . $max_page . " gibt es folgende Befehle: " . $commands );
        $self->log( 3, "<Calc> Requesting trigger index page $cur_page from $from_nick($level) on $from_channel!" );
    }
    elsif ( $message =~ m/^match\ (.*)$/i ) {
		$stats->inc_name("com-match");
        my $match_string = $1;
        my @calcs        = $calc_self->match_Calc($match_string);
        my $calc_names;
        if ( scalar(@calcs) != 0 ) {
            if ( scalar(@calcs) <= 20 ) {
                for ( my $i = 0 ; $i < scalar(@calcs) ; $i++ ) {
                    $calc_names .= $calcs[$i];
                    $calc_names .= ", " if defined $calcs[ $i + 1 ];
                }
                $irc->say(channel => $from_channel, body => $from_nick . ": Ich habe " . scalar(@calcs) . " Treffer: " . $calc_names );
            }
            else {
                $irc->say(channel => $from_channel, body => $from_nick . ": mehr als 20 Treffer (" . scalar(@calcs) . ") fuer '" . $match_string . "'! Bitte Suche einschraenken!" );
            }
        }
        else {
            $irc->say(channel => $from_channel, body => $from_nick . ": Leider keine Treffer fuer '" . $match_string . "'..." );
        }
        $self->log( 3, "<Calc> Match entry by '$match_string' from $from_nick($level) on $from_channel!" );
    }
}

1;
