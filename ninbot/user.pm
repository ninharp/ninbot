# User Module for ninBOT - https://github.com/ninharp/ninbot
# user.pm $Id$
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
package ninbot::user;

use strict;
use DBI;
use Data::Dumper;

sub new {
    my $class     = shift;
    my $self_user = {@_};

    # my $self = {
    #              '-nickhandle' => '', #string
    #              '-flags' => '',
    #              '-hosts' => [],
    #              '-identifyed' => 0,  #boolean
    #              '-passwd' => ''      #string
    #             };

    bless( $self_user, $class );
    my $self = &main::get_Self;
    $self->log( 4, "<User> Created new User object: $self_user->{-nickhandle} with flags $self_user->{-flags}" );
    my $hosts = "";
    foreach my $host (split( /\ /, $self_user->{'-hosts'} )) {
		$hosts .= $host." ";
	}
    $self->log( 6, "<User> Hosts for $self_user->{-nickhandle}: $hosts");
    return $self_user;
}

sub chk_hostmask { # ( String Hostmask )
    my ($self_user, $hostmask)  = @_;
    my $user_hosts = $self_user->{'-hosts'};
    my @hosts = split( /\ /, $user_hosts );
    foreach ( @hosts ) {
		my $host = $_;
        if ($hostmask =~ qr/$host/i) {
            return 1;    #treffer ;)
        }
    }
    return 0;
}

sub is_identifyed        # (void)
  # returns the flags if the user is identifyed to the bot, else false
{
    my $self_user = shift();
    if ( $self_user->{'-identifyed'} == 1 ) {
        return $self_user->{'-flags'};
    }
    return 0;
}

sub get_flags {
    my $self_user = shift;
    return $self_user->{'-flags'};
}

1;

