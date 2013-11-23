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
package ninbot::calc;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT} = &main::get_Self;
    $self->{_DBH} =
      $self->{_BOT}->{_DBH}; # allgemeiner dbh hier rein für allgmeeine funcs für text und sql
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
        $calc =~ s/\´/\\\´/gi;

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
    my $dbh       = $calc_self->{_DBH};
    my @entries   = $dbh->select_all( "calc", ";;;" );
    my $rand      = int( rand( scalar(@entries) ) );
    while ( $entries[$rand] =~ m/^com-/i or $entries[$rand] =~ m/^data-/i ) {
        $rand = int( rand( scalar(@entries) ) );
    }
    my $return = $entries[$rand];
    my @ret = split( /;;;/, $return );
    if ( $ret[3] =~ m/\n/ ) {
        $ret[3] =~ s/\n//g;
    }
    return @ret;
}

# Gets a random command calc
sub rand_com_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 0;
    my $dbh       = $calc_self->{_DBH};
    my @entries   = $dbh->select_all( "calc", ";;;" );
    my $rand      = int( rand( scalar(@entries) ) );
    while ( $entries[$rand] !~ m/^com-/i or $entries[$rand] =~ m/^data-/i ) {
        $rand = int( rand( scalar(@entries) ) );
    }
    my $return = $entries[$rand];
    my @ret = split( /;;;/, $return );
    if ( $ret[3] =~ m/\n/ ) {
        $ret[3] =~ s/\n//g;
    }
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

# Adds a calc
sub add_Calc {
    my $calc_self = shift;
    my $self      = &main::get_Self;
    my $ret       = 1;
    my $dbh       = $calc_self->{_DBH};
    my ( $name, $author, $calc_level, $calc_flag, $text ) = @_;
    $name =~ s/\'/\\\'/gi;
    $text =~ s/\'/\\\'/gi;
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
        my @add =
          ( $name, $text, $author, $date, $changed, $mode, $flag, $level );
        $ret = $dbh->add( "calc", @add );
        $ret = 0 if $ret == -1;
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
    my @add =
      ( $calc_name, $text, $author, $date, $changed, $mode, $flag, $level );
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
        $calc[0] =~ s/\'/\\\'/g if defined $calc[0];
        $calc[1] =~ s/\'/\\\'/g if defined $calc[1];
        $cacl[3] = $date;
        $calc[6] = $calc_flag;
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
    if ( $calc_flag =~ m/^(?:rw|ro|0)$/i ) {
        my @calc = $calc_self->get_Calc($calc_name);
        $calc[0] =~ s/\'/\\\'/g if defined $calc[0];
        $calc[1] =~ s/\'/\\\'/g if defined $calc[1];
        $cacl[3] = $date;
        $calc[7] = $calc_level;
        $ret = $dbh->update( "calc", @calc );
        return $ret;
    }
    else {
        $ret = -1;
    }
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
        if ( $row[0] =~ m/^com-/i ) {
            push( @ret, "!" . substr( $row[0], 4, length( $row[0] ) ) );
        }
        elsif ( $row[0] !~ m/^data-/i ) {
            push( @ret, $row[0] );
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
        my $command = $row[0];
        $command =~ s/^com-/$bot->{config}->{command_trigger}/i;
        push( @ret, $command );
    }
    return @ret;
}

# Calc Handler for public calcs
sub Handler {
    my $calc_self    = shift;
    my $self         = $calc_self->{_BOT};
    my $from         = shift;
    my $from_nick    = shift;
    my $from_channel = shift;
    my $message      = shift;
    my $conn         = $self->{conn};
    my $user         = $self->{_USER};
    my $trigger      = $self->{config}->{command_trigger};
    my $level        = $user->check_Level($from);

    # Crypting Routine

    #
    # Random Calc
    if ( $message =~ m/^data$/i ) {
        my @calc = $calc_self->rand_Calc;
        if ( defined $calc[0] ) {
            while ( $calc[6] !~ m/r/i and $level >= $calc[7] ) {
                @calc = $calc_self->rand_Calc;
            }
            my ( $name, $text, $author, $date, undef, undef, undef ) = @calc;
            $conn->privmsg( $from_channel, "* " . $name . " = " . $text . " [" . $author . ", " . $date . ", " . $calc[6] . "/" . $calc[7] . "]" );
        }
        else {
            $conn->privmsg( $from_channel, "* Sorry but the database is still empty ;(" );
        }
        $self->log( 3, "<Calc> Random entry from $from_nick($level) on $from_channel!" );
    }

    # Set Calc
    elsif ( $message =~ m/^data\ (.*?)\W*=\W?(.*)$/i ) {
        my $calc_name = $1;
        my $calc_text = $2;
        my $calc = $calc_self->add_Calc( $calc_name, $from_nick, 0, "rw", $calc_text );
        if ( $calc <= 0 ) {
            $conn->privmsg( $from_channel, "Schon ein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            $conn->privmsg( $from_channel, "Calc '$calc_name' hinzugefuegt!" );
        }
        $self->log( 3, "<Calc> Add entry $calc_name from $from_nick($level) on $from_channel!"
        );
    }

    # Get Calc
    elsif ( $message =~ m/^data\ (.*)$/i ) {
        my $calc_name = $1;
        if ( $calc_name !~ m/^\W*$/i ) {
            my @calc = $calc_self->get_Calc($calc_name);
            if ( !defined $calc[1] ) {
                $conn->privmsg( $from_channel, "Kein Calc fuer '$calc_name'" );
            }
            else {
                if (   $calc[6] =~ m/r/i or $calc[2] eq $from_nick and $level >= $calc[7] ) {
                    if ( length( $calc[1] ) >= 395 ) {
                        my $new_calc = substr( $calc[1], 0, 395 ) . "...";
                        $conn->privmsg( $from_channel,
							"* $calc[0] = $new_calc [$calc[2], $calc[3], $calc[6]/$calc[7]]"
                        );
                    }
                    else {
                        $conn->privmsg( $from_channel,
							"* $calc[0] = $calc[1] [$calc[2], $calc[3], $calc[6]/$calc[7]]"
                        );
                    }
                }
                else {
                    $conn->privmsg( $from_channel,
                        "Calc '$calc_name' ist privat!" );
                }
            }
            $self->log( 3, "<Calc> Requesting entry $calc_name from $from_nick($level) on $from_channel!"
            );
        }
    }

    # Plus Calc
    elsif ( $message =~ m/^data\+\ (.*)\W+=\W?(.*)$/i ) {
        my $calc_name = $1;
        my $calc_text = $2;
        my $num = $calc_self->plus_Calc( $calc_name, $from_nick, $calc_text );
        if ( $num >= 0 ) {
            $calc_name .= $num if $num != 0;
            $conn->privmsg( $from_channel, "Calc '" . $calc_name . "' hinzugefuegt!" );
        }
        else {
            $conn->privmsg( $from_channel, "Calc '" . $calc_name . "' erzeugte einen Fehler!" );
        }
        $self->log( 3, "<Calc> Increment Add entry $calc_name from $from_nick($level) on $from_channel!"
        );
    }
    
    # Modify Calc
    elsif ( $message =~ m/^data\*\ (.*)\W+=\W?(.*)$/i ) {
        my $calc_name = $1;
        my $calc_text = $2;
        my @acc_calc = $calc_self->get_Calc($calc_name);
        if ( !defined $acc_calc[1] ) {
            $conn->privmsg( $from_channel, "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            my ( $author, undef ) = split( /,/, $acc_calc[2] );
            if ( $acc_calc[6] =~ m/w/i or $author eq $from_nick and $level >= $acc_calc[7] ) {
				$calc_self->del_Calc($calc_name);
				my $calc = $calc_self->add_Calc( $calc_name, $from_nick, $acc_calc[7], $acc_calc[6], $calc_text );
				if ( $calc <= 0 ) {
					$conn->privmsg( $from_channel, "Fehler beim überschreiben von '$calc_name'!" );
				}
				else {
					#my $calc = $calc_self->mod_Calc( $calc_name, $from_nick, $calc_text );
					$conn->privmsg( $from_channel, "Calc '" . $calc_name . "' geändert!" );
					$self->log( 3, "<Calc> Modify entry $calc_name from $from_nick($level) on $from_channel!" );
				}
            }
            else {
                $conn->privmsg( $from_channel, "Calc '$calc_name' ist schreibgeschützt oder du hast nicht die nötigen Rechte!" );
                $self->log( 3, "<Calc> Modify entry $calc_name from $from_nick($level) on $from_channel failed of rights!" );
            }
        }
    }

    # Remove Calc
    elsif ( $message =~ m/^data-\ (.*)$/i ) {
        my $calc_name = $1;
        ( $calc_name, undef ) = split( /\s*=\s*/, $calc_name )
          if $calc_name =~ m/=/;
        my @acc_calc = $calc_self->get_Calc($calc_name);
        if ( !defined $acc_calc[1] ) {
            $conn->privmsg( $from_channel,
                "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            my ( $author, undef ) = split( /,/, $acc_calc[2] );
            if (   $acc_calc[6] =~ m/w/i
                or $author eq $from_nick and $level >= $acc_calc[7] )
            {
                my $calc = $calc_self->del_Calc($calc_name);
                $conn->privmsg( $from_channel, "Calc '$calc_name' gelöscht!" );
            }
            else {
                $conn->privmsg( $from_channel,
                    "Calc '$calc_name' ist schreibgeschützt!" );
            }
        }
        $self->log( 3, "<Calc> Remove entry $calc_name from $from_nick($level) on $from_channel!" );
    }

    # Calc Flag
    elsif ( $message =~ m/^dataflag\ (.*)\W+\=\W?(.*)$/i ) {
        my $calc_name = $1;
        my $calc_flag = $2;
        my @acc_calc  = $calc_self->get_Calc($calc_name);
        my ( $author, undef ) = split( /,/, $acc_calc[2] );
        if ( !defined $acc_calc[1] ) {
            $conn->privmsg( $from_channel,
                "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            if (   $author eq $from_nick
                or $acc_calc[6] =~ m/w/i and $level >= $acc_calc[7] )
            {
                if ( my $ret = $calc_self->set_Flag( $calc_name, $calc_flag ) )
                {
                    $conn->privmsg( $from_channel, "Calc Flags für '$calc_name' sind nun auf $calc_flag gesetzt!"
                    );
                }
                elsif ( $ret == -1 ) {
                    $conn->privmsg( $from_channel, "Calc Flags für '$calc_name' sind nicht korrekt!" );
                }
                else {
                    $conn->privmsg( $from_channel, "Calc Flags für '$calc_name' konnten nicht gesetzt werden!"
                    );
                }
            }
            else {
                $conn->privmsg( $from_channel, "Calc '$calc_name' ist schreibgeschützt!" );
            }
        }
        $self->log( 3, "<Calc> Set flags for entry $calc_name from $from_nick($level) on $from_channel!" );
    }

    # Calc Level
    elsif ( $message =~ m/^datalevel\ (.*)\W+\=\W?(\d*)$/i ) {
        my $calc_name  = $1;
        my $calc_level = $2;
        my @acc_calc   = $calc_self->get_Calc($calc_name);
        my ( $author, undef ) = split( /,/, $acc_calc[2] );
        if ( !defined $acc_calc[1] ) {
            $conn->privmsg( $from_channel,
                "Kein Calc fuer '$calc_name' in der Datenbank!" );
        }
        else {
            if (   $author eq $from_nick
                or $acc_calc[6] =~ m/w/i and $level >= $acc_calc[7] )
            {
                if ( $calc_level <= $level ) {
                    if ( my $ret =
                        $calc_self->set_Level( $calc_name, $calc_level ) )
                    {
                        $conn->privmsg( $from_channel, "Calc Level für '$calc_name' ist nun auf $calc_level gesetzt!" );
                    }
                    elsif ( $ret == -1 ) {
                        $conn->privmsg( $from_channel, "Calc Level für '$calc_name' ist nicht korrekt!" );
                    }
                    else {
                        $conn->privmsg( $from_channel, "Calc Level für '$calc_name' konnten nicht gesetzt werden!" );
                    }
                }
                else {
                    $conn->privmsg( $from_channel, "Calc Level $calc_level für '$calc_name' überschreitet dein eigenes Userlevel ($level)!" );
                }
            }
            else {
                $conn->privmsg( $from_channel, "Calc '$calc_name' ist schreibgeschützt!" );
            }
        }
        $self->log( 3, "<Calc> Set level for entry $calc_name from $from_nick($level) on $from_channel!" );
    }
    elsif ($message =~ m/^${trigger}(?:index|list)\W?(\d*)/i or $message =~ m/^${trigger}list\W?(\d*)/i ) {
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
        $conn->privmsg( $from_channel, $from_nick . ": Auf Seite " . $cur_page . "/" . $max_page . " gibt es folgende Befehle: " . $commands );
        $self->log( 3, "<Calc> Requesting trigger index page $cur_page from $from_nick($level) on $from_channel!" );
    }
    elsif ( $message =~ m/^match\ (.*)$/i ) {
        my $match_string = $1;
        my @calcs        = $calc_self->match_Calc($match_string);
        my $calc_names;
        if ( scalar(@calcs) != 0 ) {
            if ( scalar(@calcs) <= 20 ) {
                for ( my $i = 0 ; $i < scalar(@calcs) ; $i++ ) {
                    $calc_names .= $calcs[$i];
                    $calc_names .= ", " if defined $calcs[ $i + 1 ];
                }
                $conn->privmsg( $from_channel, $from_nick . ": Ich habe " . scalar(@calcs) . " Treffer: " . $calc_names );
            }
            else {
                $conn->privmsg( $from_channel, $from_nick . ": mehr als 20 Treffer (" . scalar(@calcs) . ") für '" . $match_string . "'! Bitte Suche einschränken!" );
            }
        }
        else {
            $conn->privmsg( $from_channel, $from_nick . ": Leider keine Treffer für '" . $match_string . "'..." );
        }
        $self->log( 3, "<Calc> Match entry by '$match_string' from $from_nick($level) on $from_channel!" );
    }
}

1;
