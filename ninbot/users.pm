# User Module for ninBOT - https://github.com/ninharp/ninbot
# users.pm $Id$
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
package ninbot::users;

use strict;
use DBI;
use Data::Dumper;
use ninbot::user;

sub new {
	my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT} = &main::get_Self;
    $self->{_BOT}->log( 3, "<Users> Initialized..." );
    $self->{_USERS} = [];
    $self->{_WHOIS} = "";
    $self->reload;
    return $self;
}

sub reload {
    my $self = shift;
    my $bot_self = &main::get_Self;
    my @users    = $bot_self->{_DBH}->select_all("user");
    $self->{_USERS} = [];
    foreach my $user_string (@users) {
        my @row               = split( /;;;/, $user_string );
        my $user_handle       = $row[0];
        my $user_hosts        = $row[1];
        my $user_flag         = $row[2];
        my $user_password     = $row[3];
        my $new_user_instance = ninbot::user->new(
            '-nickhandle' => $user_handle,     #string
            '-flags'      => $user_flag,
            '-hosts'      => $user_hosts,
            '-identifyed' => 0,                #boolean
            '-passwd'     => $user_password,
        );
        #push( @$self, $new_user_instance );
        push($self->{_USERS}, $new_user_instance);
    }
    return $self;
}

# default subroutine for undefined functions
sub AUTOLOAD {
    use vars qw($AUTOLOAD);
    my $self = &main::get_Self;
    $self->log( 5, "<Users> No function by that name: $AUTOLOAD" );
}

sub DESTROY {
    my $self = &main::get_Self;
    $self->log( 5, "<Users> Destroyed." );
}

#sub add_User { #( ninbot::users $_[0], ninbot::user $_[1])
#  my $self = &main::get_Self;
#  my $ret = -1;
#  my $user = shift();
#  my $user
#  push( @{$user} , shift() ); # neue insants von ninbot::user in das Users-Array packen
#}

sub get_Host {    # ( _SELF_, String $from )
	my $ret  = 0;
    my $self = &main::get_Self;
    my $irc = $self->{conn};
    my $users = shift;
    my $nick = shift;
    $irc->whois($nick);
    my $whois_rcvd = 0;
#    while ($whois_rcvd == 0) {
#		$whois_rcvd = 1 if $users->{_WHOIS} ne "";
#	}
	$self->{_WHOIS} = "";
    $self->log( 4, "<Users> Get Userinfo on " . $users->{_WHOIS} );
    return $ret;
}

sub set_Whois {
	my $users = shift;
	my $self = &main::get_Self;
	my @args = @_;
	$self->log( 6, "<Users> Setting Whois Temp Data for ".$args[0][1] );
	$self->{_WHOIS} = $args[0][1]."!".$args[0][2]."@".$args[0][3];
}

sub check_User {    # ( _SELF_, String $from )

    # returns 0 if not identifyed, and the user flags if the user is identfiyed
    my $self = &main::get_Self;
    my $ret  = 0;
    my ( $users,     $from )  = @_;
    my ( $from_user, $host )  = split( /\@/, $from );
    my ( $nick,      $ident ) = split( /\!/, $from_user );
    foreach my $tmp_user (@{$users->{_USERS}}) {
        if ( $tmp_user->chk_hostmask($from) ) {
            $ret = $tmp_user->is_identifyed();
            if ( $ret == 0 ) {
                $self->log( 3, "<Users> Error: $nick [$from] (Host found but not identified)!"
                );
            }
        }
    }
    $self->log( 4, "<Users> Check User " . $nick . " with host " . $from );
    return $ret;
}

sub check_Level {    # ( _SELF_, String $from )
    my ( $users, $from ) = @_;
    my $self = &main::get_Self;
    my $ret  = 0;
    $self->log( 5, "<Users> check_Level($from)" );
    my ( $from_user, $host )  = split( /\@/, $from );
    my ( $nick,      $ident ) = split( /\!/, $from_user );
    
    foreach my $tmp_user (@{$users->{_USERS}}) {
        if ( $tmp_user->chk_hostmask($from) == 1 ) {
            $ret = $tmp_user->get_flags();
        }
    }
    $self->log( 6, "<Users> check_level = Check Level " . $nick . " with host " . $from . " = " . $ret );
    return $ret;
}

# Identify user by host and password
sub active_User {
    my $self = &main::get_Self;
    my $ret  = 0;
    my ( $users, $from, $password ) = @_;
    my ( $from_user, $host )  = split( /\@/, $from );
    my ( $nick,      $ident ) = split( /\!/, $from_user );
    $self->log( 5, "<Users> active_User = Activate user $from_user with host $host" );
    foreach my $tmp_user (@{$users->{_USERS}}) {
        if ( $tmp_user->chk_hostmask($from) ) {
            if ( $tmp_user->{'-passwd'} eq
                crypt( $password, $tmp_user->{'-passwd'} ) )
            {
                $tmp_user->{'-identifyed'} = 1;    # sollte reichen, wenn ich -current_mast setze
                $tmp_user->{'-current_mask'} = $from;
                $ret = 1;
            }
        }
        else {
            $self->log( 5, "<Users> active_User = Host not matching! ($from)" );
        }
    }
    return $ret;
}
##done

# check if the $from is active (identified)
sub is_Active {
    my ( $users, $from ) = @_;
    my $self = &main::get_Self;
    $self->log( 4, "<Users> is_Active = Is user $from active?" );
    foreach my $tmp_user (@{$users->{_USERS}}) {
        if (    $tmp_user->{'-current_mask'}
            and $tmp_user->{'-current_mask'} eq $from
            and $tmp_user->is_identifyed )
        {

            # user erkannt
            return 1;
        }
    }
    return 0;
}

1;

