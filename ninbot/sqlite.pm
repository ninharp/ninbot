# Calc Module [SQLite Backend] for ninBOT - https://github.com/ninharp/ninbot
# sqlite.pm $Id$
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
package ninbot::sqlite;

use strict;
use DBI;
use DBD::SQLite;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT}         = &main::get_Self;
    $self->{_BOT}->log(2, "<SQLite> Initialize SQLite Connection");
    #$self->{_fields_user} = ();
    #$self->{_fields_calc} = ();
    #$self->{_fileds_stats} = ();
    $self->{_FIELDS} = (); 
    my $dbfile = "ninbot.sqlite";
    $self->{_DBH}  = DBI->connect("dbi:SQLite:dbname=$dbfile","","")  or print "Can't connect to the DB: $DBI::errstr\n"
      or die;
    $self->_get_fields("user");
    $self->_get_fields("data");
    $self->_get_fields("stats");
    $self->{_BOT}->log( 3, "<SQLite> Initialized..." );
    return $self;
}

sub DESTROY {
    my $backend = shift;
    $backend->{_DBH}->disconnect;
    $backend->{_BOT}->log( 3, "<SQLite> Successfully closed!..." );
}

sub check_dbi {
	my $backend = shift;
	my $self = $backend->{_BOT};
	$backend->{_DBH} ||= DBI->connect(
        $self->{_BOT}->{config}->{sql_dsn},
        $self->{_BOT}->{config}->{sql_user},
        $self->{_BOT}->{config}->{sql_password}
      );
}

# Get fields for the tables
sub _get_fields {
    my ( $backend, $database ) = @_;
    my $self = $backend->{_BOT};
    $self->log( 5, "<SQLite> Getting fields for $database" );
    my @fields;
    $backend->check_dbi();
    my $sth = $backend->{_DBH}->prepare("PRAGMA table_info($database)");
    $sth->execute;
    while ( my @row = $sth->fetchrow_array() ) {  
        $self->log(7, "<SQLite> '$database' Field: '$row[1]'");      
		if ($row[1] !~ m/^nr$/i) {
			push( @fields, $row[1] );
		}
    }
    $sth->finish;
    @{ $backend->{_FIELDS}->{$database} } = @fields;
}

# add($1, @2)
# Returns -1 if not enough parameters
# Returns 0 if the entry cant be added
# Returns 1 if the entry on database $1 with values @2 was added
# Returns 2 if the sql failed
sub add {
    return -1 if scalar(@_) < 3;
    my ( $backend, $database, @values ) = @_;
    my $self = $backend->{_BOT};
    my $ret     = 0;
    my $counter = 0;
    if ( $database =~ m/^(?:user|data|stats)$/i ) {
        if ( $database =~ m/data/i and scalar(@values) < 7 ) {
            $self->log( 4, "<SQLite> [$database] add = Not enough values for data table!" );
            last;
        } elsif ( $database =~ m/user/i and scalar(@values) < 4 ) {
            $self->log( 4, "<SQLite> [$database] add = Not enough values for user table!" );
            last;
        } elsif ( $database =~ m/stats/i and scalar(@values) < 2 ) {
			$self->log( 4, "<SQLite> [$database] add = Not enough values for stats table!" );
            last;
		}
        my @fields    = @{ $backend->{_FIELDS}->{$database} };
        foreach my $val (@values) {
            $val =~ s/^(.*)$/'$1'/;
            $values[$counter] = $val;
            $counter++;
        }
        #
        # INSERT INTO data(nr, name, value, author, time, changed, flag, level) VALUES(auto, 'com-plasma', '{ me "startet die fette Plasmawumme *TWWIIUUUTT*"; me "zielt genau auf das K\x{fffd}pfchen von &nicks Rauchger\x{fffd}t .. 3 .. 2 .. 1 .. *FFFCCHHRRRSSCCCCHHHHH*"; n_inc plasma; say "Hey! Das ist dein n_var\(plasma). !Plasmafeuer gewesen, \x{fffd}berlade unsere Ger\x{fffd}te nicht :)= ,,,"; }', 'ninharp', 'Tue Sep 23 20:37:25 2014', '', 'rw', '0')
        #INTEGER PRIMARY KEY   AUTOINCREMENT
        #
        # INSERT INTO data(name, value, author, time, changed, flag, level) VALUES('com-plasma', '{ me "startet die fette Plasmawumme *TWWIIUUUTT*"; me "zielt genau auf das K\x{fffd}pfchen von &nicks Rauchger\x{fffd}t .. 3 .. 2 .. 1 .. *FFFCCHHRRRSSCCCCHHHHH*"; n_inc plasma; say "Hey! Das ist dein n_var\(plasma\). Plasmafeuer gewesen, \x{fffd}berlade unsere Ger\x{fffd}te nicht :\)= ,,,"; }', 'ninharp', 'Tue Sep 23 21:06:19 2014', '', 'rw', '0');
        my $sql_values = join( ", ", @values );
        my $sql_fields = join( ", ", @fields );
        $self->log( 5, "<SQLite> [$database] add($database, '" . $sql_fields . "[". $sql_values . "]')" );
        $backend->check_dbi();
	print "INSERT INTO $database($sql_fields) VALUES($sql_values)\n\n";
        my $sth = $backend->{_DBH}->prepare("INSERT INTO $database($sql_fields) VALUES($sql_values)");
        if ( !$sth->execute ) {
            $ret = 2;
            $self->log( 4, "<SQLite> [$database] add = Failed SQL Statement!" );
        }
        else {
            $self->log( 4, "<SQLite> [$database] add = Added successfully! (". $values[0]. ")" );
            $ret = 1;
        }
        $sth->finish();
    }
    else {
        $self->log( 4, "<SQLite> [$database] add = Wrong database specified!" );
    }
    return $ret;
}

# match($1, $2 [, $3])
# Returns an array with all entries from column $3 that matching regexp $2 from database $1
# $3 is optional, if not defined it is set to 0 (first column)
sub match {
    return -1 if scalar(@_) < 3;
    my ( $backend, $database, $like, $column ) = @_;
    my $self = $backend->{_BOT};
    my $join = ";;;";              # join string
    $column = 0 if !defined $column;
    $self->log( 5, "<SQLite> [$database] match($database, '$like', $column)" );
    my @ret;
    if ( $database =~ m/^(?:user|data|stats)$/i ) {
        my @fields    = @{ $backend->{_FIELDS}->{$database} };
        my $field     = $fields[$column];
        $like =~ s/\'/\\\'/gi;
        $like =~ s/\´/\\\´/gi;
        $backend->check_dbi();
        my $sth =
          $backend->{_DBH}->prepare("SELECT * FROM $database WHERE $field REGEXP '$like'");
        if ( $sth->execute ) {
            while ( my @row = $sth->fetchrow_array() ) {
				if ( !defined $row[4] ) { $row[4] = ""; }
                if ( !defined $row[5] ) { $row[5] = ""; }
                if ( !defined $row[6] ) { $row[6] = ""; }
                my $return = join( $join, @row );
                push( @ret, $return );
            }
        }
        if ( scalar(@ret) <= 0 ) {
            $self->log( 5, "<SQLite> [$database] match = Nothing found! ('$like')[$column]" );
        }
        else {
            my $num_entries = $sth->rows;
            $self->log( 5, "<SQLite> [$database] match = Found $num_entries Entries ('$like')[$column]" );
        }
        $sth->finish();
    }
    else {
        $self->log( 4, "<SQLite> [$database] match = Wrong database specified!" );
    }
    return @ret;
}

# delete($1, $2 [, $3])
# Returns true if the specified entry $2 from column $3 was deleted on database $1
sub del {
    return -1 if scalar(@_) < 2;
    my ( $backend, $database, $name, $column ) = @_;
    my $self = $backend->{_BOT};
    my $ret  = 0;
    $column = 0 if !defined $column;
    $self->log( 5, "<SQLite> [$database] del($database, '$name'[$column])" );
    my @fields    = @{ $backend->{_FIELDS}->{$database} };
    my $field     = $fields[$column];
	$backend->check_dbi();
    my $sth = $backend->{_DBH}->prepare("DELETE FROM $database WHERE $field = '$name'");
    $ret = $sth->execute;
    $self->log( 4, "<SQLite> [$database] del = Deleted successfully!" ) if ( $ret != 0 );
}

# update($1, @2)
# Returns true if the data in @2 was updated on database $1
sub update {
	# add check for correct columns
    #return -1 if scalar(@_) < 5;
    my ( $backend, $database, @data ) = @_;
    my $self        = $backend->{_BOT};
    my $ret         = 0;
    my @fields      = @{ $backend->{_FIELDS}->{$database} };
    my $index_field = $fields[0];
    my $up_fields;
    my $sth;
    for ( my $i = 0 ; $i < scalar(@fields) ; $i++ ) {
		if ($database eq "data") {
			$up_fields .= $fields[$i] . "='" . $data[$i+1] . "'";
		} else {
			$up_fields .= $fields[$i] . "='" . $data[$i] . "'";
		}
        $up_fields .= ", " if $i != scalar(@fields) - 1;
    }
    $self->log( 5, "<SQLite> [$database] update($database, '$up_fields')" );
    $backend->check_dbi();
    if ($database eq "data") {
		$sth = $backend->{_DBH}->prepare( "UPDATE $database SET $up_fields WHERE $index_field='$data[1]'");
	} else {
		$sth = $backend->{_DBH}->prepare( "UPDATE $database SET $up_fields WHERE $index_field='$data[0]'");
	}
    $ret = $sth->execute;
    $self->log( 4, "<SQLite> [$database] update = Successfully updated!" ) if $ret;
    $self->log( 4, "<SQLite> [$database] update = Not updated!" ) if !$ret;
    $sth->finish;
    return $ret;
}

# select($1, $2 [, $3])
# Returns an array with the entry from column $3 that are like $2 from database $1
# $3 is optional, if not defined it is set to 0 (first column)
sub select {
    return -1 if scalar(@_) < 3;
    my ( $backend, $database, $like, $column ) = @_;
    my $self = $backend->{_BOT};
    $column = 0 if !defined $column;
    $self->log( 4, "<SQLite> [$database] select($database, '$like', $column)" );
    my @ret;
    if ( $database =~ m/^(?:user|data|stats)$/i ) {
        my @fields    = @{ $backend->{_FIELDS}->{$database} };
        my $field     = $fields[$column];
        $like =~ s/\'/\\\'/gi;
        $like =~ s/\´/\\\´/gi;
        $backend->check_dbi();
        my $sth = $backend->{_DBH}->prepare("SELECT * FROM $database WHERE $field REGEXP '$like'");
        if ( $sth->execute ) {
            @ret = $sth->fetchrow_array();
            $self->log( 4, "<SQLite> [$database] select = Found entry!" )
              if ( defined $ret[1] and $ret[$column] =~ m/$like/i );
        }
        $sth->finish();
        if ( scalar(@ret) <= 0 ) {
            $self->log( 4,
                "<SQLite> [$database] select = Nothing found! ('$like')[$column]"
            );
        }
    }
    else {
        $self->log( 4,
            "<SQLite> [$database] select = Wrong database specified!" );
    }
    return @ret;
}

# select_all($1 [, $2])
# Returns an array with all entries from database $1 joined by /$2/
# $2 is optional. default is /;;;/;
sub select_all {
    return -1 if scalar(@_) < 2;
    my ( $backend, $database, $join ) = @_;
    $join = ";;;" if !defined $join;
    my $self = $backend->{_BOT};
    $self->log( 4, "<SQLite> [$database] select_all($database, '$join')" );
    my @ret;
    if ( $database =~ m/^(?:user|data|stats)$/i ) {
        my $sth = $backend->{_DBH}->prepare("SELECT * FROM $database");
        if ( $sth->execute ) {
            while ( my @row = $sth->fetchrow_array() ) {
				if ( !defined $row[4] ) { $row[4] = ""; }
                if ( !defined $row[5] ) { $row[5] = ""; }
                if ( !defined $row[6] ) { $row[6] = ""; }
                my $return = join( $join, @row );
                push( @ret, $return );
            }
        }
        $sth->finish();
        if ( scalar(@ret) <= 0 ) {
            $self->log( 4, "<SQLite> [$database] select_all = Nothing returned!" );
        }
        else {
            $self->log( 4, "<SQLite> [$database] select_all = Returned " . scalar(@ret) . " entries!" );
        }
    }
    else {
        $self->log( 4,
            "<SQLite> [$database] select_all = Wrong database specified!" );
    }
    return @ret;
}

1;
