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
package ninBot::Calc;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT} = &main::get_Self;
    $self->{_DBH} = $self->{_BOT}->{_DBH}; # allgemeiner dbh hier rein für allgmeeine funcs für text und sql
    $self->{_BOT}->log( 3, "<Calc> Initialized..." );
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
        @ret = $dbh->select( "calc", "^" . $calc . "\$" );
    }
    return @ret;
}

# Gets a random calc
sub rand_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 0;
    my $field	  = 1;
    my $not		  = 0;
    my $filter	  = "^com-.*";
    my $dbh       = $calc_self->{_DBH};
    my @entry 	  = $dbh->random( "calc", ";;;", $field, $not, $filter );
    my @ret = split( /;;;/, $entry[0] );
    if ( $ret[4] =~ m/\n/ ) {
        $ret[4] =~ s/\n//g;
    }
    return @ret;
#    my @entries   = $dbh->select_all( "calc", ";;;" );
#    my $rand      = int( rand( scalar(@entries) ) );
#    while ( $entries[$rand] =~ m/;;;com-/i or $entries[$rand] =~ m/;;;data-/i ) {
#        $rand = int( rand( scalar(@entries) ) );
#    }
#    my $return = $entries[$rand];
#    #print $return."\n\n\n";
#    my @ret = split( /;;;/, $return );
#    if ( $ret[4] =~ m/\n/ ) {
#        $ret[4] =~ s/\n//g;
#    }
#    return @ret;

}

# Gets a random command calc
sub rand_com_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 0;
    my $field	  = 1;
    my $not		  = 1;
    my $filter	  = "^com-.*";
    my $dbh       = $calc_self->{_DBH};
    my @entry 	  = $dbh->random( "calc", ";;;", $field, $not, $filter );
    my @ret = split( /;;;/, $entry[0] );
    if ( $ret[4] =~ m/\n/ ) {
        $ret[4] =~ s/\n//g;
    }
    return @ret;
#    my @entries   = $dbh->select_all( "calc", ";;;" );
#    my $rand      = int( rand( scalar(@entries) ) );
#    while ( $entries[$rand] !~ m/^com-/i or $entries[$rand] =~ m/^data-/i ) {
#        $rand = int( rand( scalar(@entries) ) );
#    }
#    my $return = $entries[$rand];
#    my @ret = split( /;;;/, $return );
#    if ( $ret[4] =~ m/\n/ ) {
#        $ret[4] =~ s/\n//g;
#    }
#    return @ret;
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

# Adds a calc
sub add_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 1;
    my $dbh       = $calc_self->{_DBH};
    my ( $name, $author, $calc_level, $calc_flag, $text ) = @_;
    $name =~ s/\'/\'\'/gi;
    $text =~ s/\'/\'\'/gi;
    #$text =~ s/\(/\\\(/g;
    #$text =~ s/\)/\\\(/g;
    $self->log( 3, "<Calc> Added a new calc '" . $name . "'" );

    # array should be like this
    # name - value - author - time - changed - mode - flag - level
    my $date = localtime();
    my @calc = $calc_self->get_Calc($name);
    if ( defined $calc[1] ) {
        $ret = 0;
    }
    else {
        my $flag    = $calc_flag;
        my $mode    = 0;
        my $changed = "";
        my $level   = $calc_level;
        my @add = ( $name, $text, $author, $date, $changed, $flag, $level );
        $ret = $dbh->add( "calc", @add );
        #$ret = 0 if $ret == -1;
    }
    return $ret;
}

# Adds a calc by name plus increasing number,
# depends on how many same name entries are there
sub plus_Calc {
    my ( $calc_self, $name, $author, $text ) = @_;
    my $self      = &main::get_Self;
    my $dbh       = $calc_self->{_DBH};
    my $ret       = 0;
    my $date      = localtime();
    my $num       = 0;
    my $calc_name = $name;
    my @calc      = $calc_self->get_Calc($calc_name);
    while ( defined $calc[1] ) {
        $num++;
        $calc_name = $name . $num;
        @calc      = $calc_self->get_Calc($calc_name);
    }
    my $flag    = "rw";
    my $mode    = 0;
    my $changed = "";
    my $level   = 0;
    my @add = ( $calc_name, $text, $author, $date, $changed, $flag, $level );
    $ret = $dbh->add( "calc", @add );
    if ( $ret == 2 or $ret == -1 ) {
        $ret = -1;
    }
    else {
        $ret = $num;
    }
    return $ret;
}

# Sets a flag for a calc
sub set_Flag {
    my ( $calc_self, $calc_name, $calc_flag ) = @_;
    my $dbh  = $calc_self->{_DBH};
    my $ret  = 0;
    my $date = localtime();
    if ( $calc_flag =~ m/^(?:rw|ro|0)$/i ) {
        my @calc = $calc_self->get_Calc($calc_name);
        $calc[0] =~ s/\'/\\\'/g if defined $calc[1];
        $calc[1] =~ s/\'/\\\'/g if defined $calc[2];
        $calc[3] = $date;
        $calc[5] = $calc_flag;
        #print Dumper(@calc);
        $ret = $dbh->update( "calc", @calc );
        return $ret;
    }
    else {
        $ret = -1;
    }
}

# Sets a level for a calc
sub set_Level {
    my ( $calc_self, $calc_name, $calc_level ) = @_;
    my $dbh  = $calc_self->{_DBH};
    my $ret  = 0;
    my $date = localtime();
    my @calc = $calc_self->get_Calc($calc_name);
    $calc_level = 0 if ($calc_level > 10 or $calc_level < 0);
    $calc[1] =~ s/\'/\\\'/g if defined $calc[0];
    $calc[2] =~ s/\'/\\\'/g if defined $calc[1];
    $calc[4] = $date;
    $calc[7] = $calc_level;
    $ret = $dbh->update( "calc", @calc );
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
    my @com_entries = $dbh->match( "calc", "^com-" );
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
        my $name = $calc[1];
        my $value = $calc[2];
        my $author = $calc[3];
        my $date = $calc[4];
        my $changed = $calc[5];
        my $flag = $calc[6];
        my $clevel = $calc[7];
        if ( defined $name ) {
            while ($flag !~ m/r/i and $level <= $clevel) {
                @calc = $calc_self->rand_Calc;
				$name = $calc[1];
				$value = $calc[2];
				$author = $calc[3];
				$date = $calc[4];
				$changed = $calc[5];
				$flag = $calc[6];
				$clevel = $calc[7];
            }
            ( $nr, $name, $value, $author, $date, $changed, $flag, $clevel ) = @calc;
            
            $irc->say(channel =>  $from_channel, body => "* " . $name . " = " . $value . " [" . $author . ", " . $date . ", " . $flag . "/" . $clevel . "]");
        }
        else {
            $irc->say(channel =>  $from_channel, body => "* Sorry but the database is still empty ;(" );
        }
        $self->log( 3, "<Calc> Random entry from $from_nick($level) on $from_channel!" );
    }

    # Set Calc
    elsif ( $message =~ m/^calc\ (.*?)\W*=\W?(.*)$/i ) {
		$stats->inc_name("com-dataset");
        my $calc_name = $1;
        my $calc_text = $2;
        my $calc = $calc_self->add_Calc( $calc_name, $from_nick, 0, "rw", $calc_text );
        if ( $calc <= 0 ) {
            $irc->say(channel =>  $from_channel, body => "Schon ein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' hinzugefuegt!" );
        }
        $self->log( 3, "<Calc> Add entry $calc_name from $from_nick($level) on $from_channel!"
        );
    }

    # Get Calc
    elsif ( $message =~ m/^calc\ (.*)$/i ) {
		$stats->inc_name("com-dataget");
        my $calc_name = $1;
        if ( $calc_name !~ m/^\W*$/i ) {
            my @calc = $calc_self->get_Calc($calc_name);
			my $name = $calc[1];
			my $value = $calc[2];
			my $author = $calc[3];
			my $date = $calc[4];
			my $changed = $calc[5];
			my $flag = $calc[6];
			my $clevel = $calc[7];
            if ( !defined $name ) {
                $irc->say(channel =>  $from_channel, body => "Kein Calc fuer '$calc_name'" );
            }
            else {
                if ( $author eq $from_nick or $flag =~ m/w/i and $level >= $clevel or $level == 10 ) {
                    if ( length( $calc[1] ) >= 395 ) {
                        $value = substr( $value, 0, 395 ) . "...";
                    }
                    $irc->say(channel =>  $from_channel, body => "* $name = $value [$author, $date, $flag/$clevel]" );
                }
                else {
                    $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' ist privat!" );
                }
            }
            $self->log( 3, "<Calc> Requesting entry $calc_name from $from_nick($level) on $from_channel!");
        }
    }

    # Plus Calc
    elsif ( $message =~ m/^calc\+\ (.*?)\W+=\W?(.*)$/i ) {
		$stats->inc_name("com-dataplus");
        my $calc_name = $1;
        my $calc_text = $2;
        my $num = $calc_self->plus_Calc( $calc_name, $from_nick, $calc_text );
        if ( $num >= 0 ) {
            $calc_name .= $num if $num != 0;
            $irc->say(channel =>  $from_channel, body => "Calc '" . $calc_name . "' hinzugefuegt!" );
        }
        else {
            $irc->say(channel =>  $from_channel, body => "Calc '" . $calc_name . "' erzeugte einen Fehler!" );
        }
        $self->log( 3, "<Calc> Increment Add entry $calc_name from $from_nick($level) on $from_channel!"
        );
    }
    
    # Modify Calc
    elsif ( $message =~ m/^calc\*\ (.*?)\W+=\W?(.*)$/i ) {
		$stats->inc_name("com-datamod");
        my $calc_name = $1;
        my $calc_text = $2;
        my $isnew = 0;
        my @acc_calc = $calc_self->get_Calc($calc_name);
        if ( !defined $acc_calc[1] ) {
            #$irc->say(channel =>  $from_channel, "Kein Calc fuer '$calc_name' in der Datenbank!" );
            $acc_calc[7] = 0;
            $acc_calc[6] = "rw";
            $acc_calc[3] = $from_nick;
            $isnew = 1;
        }
        my $clevel = $acc_calc[7];
        my $flag = $acc_calc[6];
        my ( $author, undef ) = split( /,/, $acc_calc[1] );
        if ( $author eq $from_nick or $flag =~ m/w/i and $level >= $clevel or $level == 10 ) {
			$calc_self->del_Calc($calc_name);
			$acc_calc[3] =~ s/\ changed by\ .*$//ig;
			$acc_calc[3] = $acc_calc[3]." changed by ". $from_nick;
			my $calc = $calc_self->add_Calc( $calc_name, $acc_calc[4], $acc_calc[7], $acc_calc[6], $calc_text );
			if ( $calc <= 0 ) {
				$irc->say(channel =>  $from_channel, body => "Fehler beim Ueberschreiben von '$calc_name'!" );
			}
			else {
				#my $calc = $calc_self->mod_Calc( $calc_name, $from_nick, $calc_text );
				if ($isnew == 0) {
					$irc->say(channel =>  $from_channel, body => "Calc '" . $calc_name . "' geaendert!" );
				} else {
					$irc->say(channel =>  $from_channel, body => "Calc '" . $calc_name . "' angelegt!" );
				}
				$self->log( 3, "<Calc> Modify entry $calc_name from $from_nick($level) on $from_channel!" );
			}
        }
        else {
			$irc->say(channel =>  $from_channel, body => "Calc '$calc_name' ist schreibgeschuetzt oder du hast nicht die noetigen Rechte!" );
            $self->log( 3, "<Calc> Modify entry $calc_name from $from_nick($level) on $from_channel failed of rights!" );
        }
    }

    # Remove Calc
    elsif ( $message =~ m/^calc-\ (.*)$/i ) {
		$stats->inc_name("com-datadel");
        my $calc_name = $1;
        ( $calc_name, undef ) = split( /\s*=\s*/, $calc_name )
          if $calc_name =~ m/=/;
        my @acc_calc = $calc_self->get_Calc($calc_name);
        if ( !defined $acc_calc[1] ) {
            $irc->say(channel =>  $from_channel, body => "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            my ( $author, undef ) = split( /,/, $acc_calc[1] );
            my $clevel = $acc_calc[7];
            my $flag = $acc_calc[6];
             if ( $author eq $from_nick or $flag =~ m/w/i and $level >= $clevel or $level == 10 ) {
                my $calc = $calc_self->del_Calc($calc_name);
                $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' geloescht!" );
                if ($calc_name =~ /^com-/) {
					$stats->del_name($calc_name);
				}
            }
            else {
                $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' ist schreibgeschuetzt!" );
            }
        }
        $self->log( 3, "<Calc> Remove entry $calc_name from $from_nick($level) on $from_channel!" );
    }

    # Calc Flag
    elsif ( $message =~ m/^calcflag\ (.*)\W+\=\W?(.*)$/i ) {
		$stats->inc_name("com-dataflag");
        my $calc_name = $1;
        my $calc_flag = $2;
        my @acc_calc  = $calc_self->get_Calc($calc_name);
		my $name = $acc_calc[1];
		my $value = $acc_calc[2];
		my $author = $acc_calc[3];
		my $date = $acc_calc[4];
		my $changed = $acc_calc[5];
		my $flag = $acc_calc[6];
		my $clevel = $acc_calc[7];
        #my ( $author, undef ) = split( /,/, $acc_calc[2] );
        if ( !defined $value ) {
            $irc->say(channel =>  $from_channel, body => "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            if ( $author eq $from_nick or $flag =~ m/w/i and $level >= $clevel or $level == 10 )
            {
                if ( my $ret = $calc_self->set_Flag( $calc_name, $calc_flag ) )
                {
                    $irc->say(channel =>  $from_channel, body => "Calc Flags fuer '$calc_name' sind nun auf $calc_flag gesetzt!" );
                }
                elsif ( $ret == -1 ) {
                    $irc->say(channel =>  $from_channel, body => "Calc Flags fuer '$calc_name' sind nicht korrekt!" );
                }
                else {
                    $irc->say(channel =>  $from_channel, body => "Calc Flags fuer '$calc_name' konnten nicht gesetzt werden!" );
                }
            }
            else {
                $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' ist schreibgeschuetzt!" );
            }
        }
        $self->log( 3, "<Calc> Set flags for entry $calc_name from $from_nick($level) on $from_channel!" );
    }

    # Calc Level
    elsif ( $message =~ m/^calclevel\ (.*)\W+\=\W?(\d*)$/i ) {
		$stats->inc_name("com-datalevel");
        my $calc_name  = $1;
        my $calc_level = $2;
        my @acc_calc   = $calc_self->get_Calc($calc_name);
		my $name = $acc_calc[1];
		my $value = $acc_calc[2];
		my $author = $acc_calc[3];
		my $date = $acc_calc[4];
		my $changed = $acc_calc[5];
		my $flag = $acc_calc[6];
		my $clevel = $acc_calc[7];
        #my ( $author, undef ) = split( /,/, $acc_calc[2] );
        if ( !defined $acc_calc[0] ) {
            $irc->say(channel =>  $from_channel, body => "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            if ( $author eq $from_nick or $flag =~ m/w/i and $level >= $clevel or $level == 10 ) {
                if ( $calc_level <= $level ) {
                    if ( my $ret = $calc_self->set_Level( $calc_name, $calc_level ) )
                    {
                        $irc->say(channel =>  $from_channel, body => "Calc Level fuer '$calc_name' ist nun auf $calc_level gesetzt!" );
                    }
                    elsif ( $ret == -1 ) {
                        $irc->say(channel =>  $from_channel, body => "Calc Level fuer '$calc_name' ist nicht korrekt!" );
                    }
                    else {
                        $irc->say(channel =>  $from_channel, body => "Calc Level fuer '$calc_name' konnten nicht gesetzt werden!" );
                    }
                }
                else {
                    $irc->say(channel =>  $from_channel, body => "Calc Level $calc_level fuer '$calc_name' ueberschreitet dein eigenes Userlevel ($level)!" );
                }
            }
            else {
                $irc->say(channel =>  $from_channel, body => "Calc '$calc_name' ist schreibgeschuetzt!" );
            }
        }
        $self->log( 3, "<Calc> Set level for entry $calc_name from $from_nick($level) on $from_channel!" );
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
