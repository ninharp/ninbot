package ninbot::textdb;

# Calc Module [textDB Backend] for ninBOT - https://github.com/ninharp/ninbot
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
use DBI;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT} = &main::get_Self;
    $self->{_BOT}->log( 3, "<textDB> Initialized..." );
    $self->{config} = $self->{_BOT}->{config};
    return $self;
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
    $self->log( 4,
            "<textDB> [$database] add($database, '" 
          . @values . "["
          . scalar(@values)
          . "]')" );
    my $ret     = 0;
    my $counter = 0;
    if ( $database =~ m/^(?:user|calc)$/i ) {
        if ( $database =~ m/calc/i and scalar(@values) < 8 ) {
            $self->log( 4, "<textDB> [$database] add = Not enough values!" );
            last;
        }
        elsif ( $database =~ m/user/i and scalar(@values) < 4 ) {
            $self->log( 4, "<textDB> [$database] add = Not enough values!" );
            last;
        }
        my $db_file = lc($database) . "_file";
        my $file    = $self->{config}->{$db_file};
        if ( open( DB, "<$file" ) ) {
            my @db = <DB>;
            close(DB);
            if ( open( DB, ">>$file" ) ) {
                print DB join( ";;;", @values ) . "\n";
                close(DB);
                $self->log( 4,
"<textDB> [$database] add = Added successfully! ($values[0])"
                );
                $ret = 1;
            }
            else {
                $self->log( 4,
"<textDB> [$database] add = Cannot open file $file for writing!"
                );
            }
        }
        else {
            $self->log( 4,
                "<textDB> [$database] add = Cannot open file $file." );
            exit(1);
        }
    }
    else {
        $self->log( 4, "<textDB> [$database] add = Wrong database specified!" );
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
    $self->log( 4, "<textDB> [$database] match($database, '$like', $column)" );
    my @ret;
    if ( $database =~ m/^(?:user|calc)$/i ) {
        my $db_file = lc($database) . "_file";
        my $file    = $self->{config}->{$db_file};
        if ( open( DB, "<$file" ) ) {
            my @db = <DB>;
            close(DB);
            foreach my $entry (@db) {
                my @row = split( /;;;/, $entry );
                if ( $row[$column] =~ m/$like/i ) {
                    push( @ret, $entry );
                }
            }
        }
        else {
            $self->log( 4,
                "<textDB> [$database] match = Cannot open file $file." );
            exit(1);
        }
        if ( scalar(@ret) <= 0 ) {
            $self->log( 4, "<textDB> [$database] match = Nothing returned!" );
        }
        else {
            $self->log( 4,
                    "<textDB> [$database] match = Found "
                  . scalar(@ret)
                  . " entries!" );
        }
    }
    else {
        $self->log( 4,
            "<textDB> [$database] match = Wrong database specified!" );
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
    $self->log( 4, "<textDB> [$database] del($database, '$name'[$column])" );
    if ( $database =~ m/^(?:user|calc)$/i ) {
        my $db_file = lc($database) . "_file";
        my $file    = $self->{config}->{$db_file};
        my @new_db;
        if ( open( DB, "<$file" ) ) {
            my @db = <DB>;
            close(DB);
            foreach my $entry (@db) {
                my @row = split( /;;;/, $entry );
                if ( $row[$column] !~ m/^$name$/i ) {
                    push( @new_db, $entry );
                }
                else {
                    $self->log( 4,
                        "<textDB> [$database] del = Deleted successfully!" )
                      if ( $ret != 0 );
                    $ret = 1;
                }
            }
            if ( scalar(@new_db) != scalar(@db) ) {
                if ( open( DB, ">$file" ) ) {
                    print DB @new_db;
                    close(DB);
                }
                else {
                    $self->log( 4,
"<textDB> [$database] del = Cannot open file $file for writing!"
                    );
                }
            }
        }
        else {
            $self->log( 4,
                "<textDB> [$database] del = Cannot open file $file." );
            exit(1);
        }
    }
    else {
        $self->log( 4, "<textDB> [$database] del = Wrong database specified!" );
    }

}

# update($1, @2)
# Returns true if the data in @2 was updated on database $1
sub update {
    return -1 if scalar(@_) < 5;
    my ( $backend, $database, @data ) = @_;
    my $self   = $backend->{_BOT};
    my $ret    = 0;
    my $column = 0;
    $self->log( 4, "<textDB> [$database] update($database, '@data')" );
    if ( $database =~ m/^(?:user|calc)$/i ) {
        my $db_file       = lc($database) . "_file";
        my $file          = $self->{config}->{$db_file};
        my $updated_entry = join( ";;;", @data );
        my @new_db;
        if ( open( DB, "<$file" ) ) {
            my @db = <DB>;
            close(DB);
            foreach my $entry (@db) {
                my @row = split( /;;;/, $entry );
                if ( $row[$column] !~ m/^$data[$column]$/i ) {
                    push( @new_db, $entry );
                }
                else {
                    push( @new_db, $updated_entry );
                    $self->log( 4,
                        "<textDB> [$database] update = Updated successfully!" )
                      if ( $ret != 0 );
                    $ret = 1;
                }
            }
            if ( $ret == 1 ) {
                if ( open( DB, ">$file" ) ) {
                    print DB @new_db;
                    close(DB);
                }
                else {
                    $self->log( 4,
"<textDB> [$database] update = Cannot open file $file for writing!"
                    );
                }
            }
        }
        else {
            $self->log( 4,
                "<textDB> [$database] update = Cannot open file $file." );
            exit(1);
        }
    }
    else {
        $self->log( 4,
            "<textDB> [$database] update = Wrong database specified!" );
    }
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
    $self->log( 4, "<textDB> [$database] select($database, '$like', $column)" );
    my @ret;
    if ( $database =~ m/^(?:user|calc)$/i ) {
        my $db_file = lc($database) . "_file";
        my $file    = $self->{config}->{$db_file};
        if ( open( DB, "<$file" ) ) {
            my @db = <DB>;
            close(DB);
            foreach my $entry (@db) {
                my @row = split( /;;;/, $entry );
                if ( $row[$column] =~ m/$like/i ) {
                    @ret = @row;
                    last;
                }
            }
        }
        else {
            $self->log( 4,
                "<textDB> [$database] select = Cannot open file $file." );
            exit(1);
        }
        if ( scalar(@ret) <= 0 ) {
            $self->log( 4, "<textDB> [$database] select = Nothing returned!" );
        }
        else {
            $self->log( 4, "<textDB> [$database] select = Found entry!" );
        }
    }
    else {
        $self->log( 4,
            "<textDB> [$database] select = Wrong database specified!" );
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
    $self->log( 4, "<textDB> [$database] select_all($database, '$join')" );
    my @ret;
    if ( $database =~ m/^(?:user|calc)$/i ) {
        my $db_file = lc($database) . "_file";
        my $file    = $self->{config}->{$db_file};
        if ( open( DB, "<$file" ) ) {
            my @db = <DB>;
            close(DB);
            foreach my $entry (@db) {
                my @row = split( /;;;/, $entry );
                my $return = join( $join, @row );
                push( @ret, $return );
            }
        }
        else {
            $self->log( 4,
                "<textDB> [$database] select_all = Cannot open file $file." );
            exit(1);
        }
        if ( scalar(@ret) <= 0 ) {
            $self->log( 4,
                "<textDB> [$database] select_all = Nothing returned!" );
        }
        else {
            $self->log( 4,
                    "<textDB> [$database] select_all = Returned "
                  . scalar(@ret)
                  . " entries!" );
        }
    }
    else {
        $self->log( 4,
            "<textDB> [$database] select_all = Wrong database specified!" );
    }
    return @ret;
}

###### Old Crud
# Gets a random calc
#sub rand_Calc {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $ret = 0;
#  my @ret;
#  my $config = $self->{config};
#  if (!open(C, "<$config->{calc_file}")) {
#    print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
#    exit(1);
#  }
#  my @C = <C>;
#  close(C);
#  if (scalar(@C) >= 3) {
#    my $rand = int(rand(scalar(@C)));
#    $ret = $C[$rand];
#    while ($ret =~ m/^data-/ or $ret =~ m/^#/) {
#      $rand = int(rand(scalar(@C)));
#      $ret = $C[$rand];
#    }
#    chomp($ret);
#    @ret = split(/;;;/, $ret);
#  }
#  return @ret;
#}

## Get a calc by name
#sub get_Calc {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my @ret;
#  my $calc = shift;
#  open(C, "<$config->{calc_file}");
#  my @C = <C>;
#  close(C);
#  foreach (@C) {
#    next if ($_ =~ m/^#/);
#    chomp($_);
#    my @calc = split(/;;;/, $_);
#    my $name = $calc[0];
#    if ($calc =~ m/^$name$/i) {
#      @ret = @calc;
#    }
#  }
#  return @ret;
#}

## Deletes a calc
#sub del_Calc {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my $ret = 0;
#  my $name = shift;
#  if (!open(C, "<$config->{calc_file}")) {
#    print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
#    exit(1);
#  }
#  my @calcs = <C>;
#  close(C);
#  print "CALC: ".scalar(@calcs)."\n";
#  my @new_calcs;
#  foreach my $old_calc (@calcs) {
#    my ($calc_name, undef, undef, undef) = split(/;;;/, $old_calc);
#    push(@new_calcs, $old_calc) if $calc_name !~ m/^$name$/i;
#    $ret = 1 if $calc_name =~ m/^$name$/i;
#  }
#  open(C, ">$config->{calc_file}");
#  foreach my $new_calc (@new_calcs) {
#    print C $new_calc;
#  }
#  close(C);
#  return $ret;
#}

## Adds a calc
#sub add_Calc {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my $ret = 0;
#  my ($name,$author,$text) = @_;
#  # name;;;value;;;author;;;time;;;changed;;;mode;;;flag;;;level
#  $self->log(3, "Added a new calc '".$name."'");
#  my $date = localtime();
#  #    $name =~ s/(.*)\W*$/$1/;
#  #    $name =~ s/\W*(.*)$/$1/;
#  if (scalar($calc_self->get_Calc($name)) == 0) {
#    open(C, ">>$config->{calc_file}");
#    print C "$name;;;$text;;;$author;;;$date;;;;;;0;;;rw;;;0\n";
#    close(C);
#    $ret = 1;
#  }
#  return $ret;
#}

## Adds a calc by name plus increasing number,
## depends on how many same name entries are there
#sub plus_Calc {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my $ret = 0;
#  my ($name,$author,$text) = @_;
#  my $date = localtime();
#  #$name =~ s/(.*)\W*$/$1/;
#  #$text =~ s/^\W*(.*)/$1/;
#  my $num = 0;
#  my $calc_name = $name;
#  while ($calc_self->get_Calc($calc_name) !~ m/^0$/) {
#    $num++;
#    $calc_name = $name . $num;
#  }
#  if ($calc_self->get_Calc($calc_name) =~ m/^0$/) {
#    open(C, ">>$config->{calc_file}");
#    print C "$calc_name;;;$text;;;$author;;;$date;;;;;;0;;;rw;;;0\n";
#    close(C);
#    $ret = $num;
#  }
#  else {
#    $ret = -1;
#  }
#  return $ret;
#}

## Matches calcs by match string
#sub match_Calc {
#  my $calc_self = shift;
#  my $match_string = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  $match_string =~ s/\*/\.\*/g;
#  $match_string =~ s/\'/\\\'/g;
#  $match_string = "^(data-)?".$match_string;
#  my @ret;
#  if (!open(C, "<$config->{calc_file}")) {
#    print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
#    exit(1);
#  }
#  my @C = <C>;
#  close(C);
#  foreach (@C) {
#    next if $_ =~ m/^#/;
#    my ($name,undef,undef,undef) = split(/;;;/, $_);
#    if ($name =~ m/$match_string/i and $name !~ m/^data-/i) {
#      push(@ret, $name);
#    }
#  }
#  return @ret;
#}

## lists data-com-* commands
#sub list_Com {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my @ret = ();
#  if (!open(C, "<$config->{calc_file}")) {
#    print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
#    exit(1);
#  }
#  my @C = <C>;
#  close(C);
#  foreach (@C) {
#    next if $_ =~ m/^#/;
#    my ($name,undef,undef,undef, undef, undef, undef, undef) = split(/;;;/, $_);
#    if ($name =~ m/^data-com-(.*)/i) {
#      push(@ret, $config->{command_trigger}.$1);
#    }
#  }
#  return sort @ret;
#}

## Sets a flag for a calc
#sub set_Flag {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my $ret = 0;
#  my ($calc_name,$calc_flag) = @_;
#  my $date = localtime();
#  if (!open(C, "<$config->{calc_file}")) {
#    print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
#    exit(1);
#  }
#  my @calcs = <C>;
#  close(C);
#  print "CALC: ".scalar(@calcs)."\n";
#  my @new_calcs;
#  foreach my $old_calc (@calcs) {
#    my ($c_name, undef, undef, undef, undef, undef, undef, undef) = split(/;;;/, $old_calc);
#    if ($c_name =~ m/^$calc_name$/i) {
#      my @calc = split(/;;;/, $old_calc);
#      my $old_calc = "$calc[0];;;$calc[1];;;$calc[2];;;$date;;;$calc[4];;;$calc[5];;;$calc_flag;;;$calc[7]";
#      push(@new_calcs, $old_calc);
#      $ret = 1;
#    }
#    else {
#      push(@new_calcs, $old_calc);
#    }
#  }
#  open(C, ">$config->{calc_file}");
#  foreach my $new_calc (@new_calcs) {
#    print C $new_calc;
#  }
#  close(C);
#  return $ret;
#}

## Sets a level for a calc
#sub set_Level {
#  my $calc_self = shift;
#  my $self = &main::get_Self;
#  my $config = $self->{config};
#  my $ret = 0;
#  my ($calc_name,$calc_level) = @_;
#  my $date = localtime();
#  if (!open(C, "<$config->{calc_file}")) {
#    print STDOUT "Error: $! => ./$self->{config}->{channel_file}\nYou have to run the install.sh script if you run for the first time!\n";
#    exit(1);
#  }
#  my @calcs = <C>;
#  close(C);
#  print "CALC: ".scalar(@calcs)."\n";
#  my @new_calcs;
#  foreach my $old_calc (@calcs) {
#    my ($c_name, undef, undef, undef, undef, undef, undef, undef) = split(/;;;/, $old_calc);
#    if ($c_name =~ m/^$calc_name$/i) {
#      my @calc = split(/;;;/, $old_calc);
#      my $old_calc = "$calc[0];;;$calc[1];;;$calc[2];;;$date;;;$calc[4];;;$calc[5];;;$calc[6];;;$calc_level";
#      push(@new_calcs, $old_calc);
#      $ret = 1;
#    }
#    else {
#      push(@new_calcs, $old_calc);
#    }
#  }
#  open(C, ">$config->{calc_file}");
#  foreach my $new_calc (@new_calcs) {
#    print C $new_calc;
#  }
#  close(C);
#  return $ret;
#}

1;
