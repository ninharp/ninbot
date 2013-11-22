package ninbot::channel;
# Channel Module for ninBOT - http://ninbot.sourceforge.net
# $Header: /cvsroot/ninbot/ninbot/ninbot/channel.pm,v 1.1 2003/04/25 11:22:41 prahnin Exp $
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
  my $channel_self = { @_ };
  $channel_self->{_MUTE} = 0;
  bless ($channel_self, $class);
  
  my $self = &main::get_Self;
  my $conn = $self->{conn};
  
  my $channel = $channel_self->{_NAME};
  $conn->join($channel);
  $self->log(4, "<Channel> Created new channel object ($channel)");
  return $channel_self;
}

# routine for module closing
sub DESTROY {
  my $self = &main::get_Self;
  $self->log(3, "<Channel> Destroyed.");
}

# muting channel
sub mute {
	my $channel_self = shift;
	my $self = &main::get_Self;
	$self->log(4, "<Channel> Muting channel $channel_self->{_NAME}");
	$channel_self->{_MUTE} = 1;
}

# unmuting channel
sub unMute {
	my $channel_self = shift;
	my $self = &main::get_Self;
	$self->log(4, "<Channel> Unmuting channel $channel_self->{_NAME}");
	$channel_self->{_MUTE} = 0;
}

# is channel muted
sub isMuted {
	my $channel_self = shift;
	my $self = &main::get_Self;
	$self->log(4, "<Channel> isMuted $channel_self->{_NAME} = $channel_self->{_MUTE}");
	if ($channel_self->{_MUTE} == 1) {
		return 1;
	} else {
		return 0;
	}
}

# Is Channel a permanent Channel
sub is_PermChan {
  my ($channel_self, $chan) = @_;
  my $self = &main::get_Self;
  my $ret = 0;
  foreach my $pchan (keys %{$self->{channels}}) {
    $ret = 1 if ($chan eq $pchan);
#    return 1 if ($chan eq $pchan);
  }
  return $ret;
}

sub add_name {
  my ($channel_self, $name) = @_;
  my $self = &main::get_Self;
  if (defined $channel_self->{_NAMES}) {
	if ($channel_self->{_NAMES} !~ m/$name/) {
		$self->log(3, "<Channel> Adding Nickname $name to Channel ".$channel_self->{_NAME}." Names list");
		$channel_self->{_NAMES} .= $name." ";
	}
	$self->log(5, "<Channel> Names: ".$channel_self->{_NAMES});
  }
}

sub del_name {
  my ($channel_self, $name) = @_;
  my $self = &main::get_Self;
  if ($channel_self->{_NAMES} =~ m/$name/) {
	$self->log(3, "<Channel> Deleting Nickname $name from Channel ".$channel_self->{_NAME}." Names list");
	$channel_self->{_NAMES} =~ s/$name\ //;
	$self->log(5, "<Channel> Names: ".$channel_self->{_NAMES});
  }
}

sub change_name {
  my ($channel_self, $name, $newname) = @_;
  my $self = &main::get_Self;
  if ($channel_self->{_NAMES} =~ m/$name/) {
	$self->log(3, "<Channel> Changing Nickname $name to $newname on Channel ".$channel_self->{_NAME}." Names list");
	$channel_self->{_NAMES} =~ s/$name/$newname/;
	$self->log(5, "<Channel> Names: ".$channel_self->{_NAMES});
  }
}

sub close_channel {
  my $channel_self = shift;
  my $self = &main::get_Self;
  delete $self->{_CHANNEL}->{$channel_self->{_NAME}};
  $self->log(3, "<Channel> Closing Channel ".$channel_self->{_NAME});
}

sub fill_names {
  # onjoin neu fuellen?
  my ($channel_self, $names) =  @_;
  my $self = &main::get_Self;
  my $conn = $self->{conn};
  my $out;
  foreach my $name (split(" ", $names)) {
	  if ($name =~ m/^(\@|\+|\%)/i) {
		  $name =~ s/^.(.*)$/$1/i;
	  }
	  $out .= $name." ";
  }
  $self->log(4, "<Channel> Fill in Channel name list for ".$channel_self->{_NAME}.": ".$out);
  $channel_self->{_NAMES} = $out;
}


1;

