# Statistic Module for ninBOT - https://github.com/ninharp/ninbot
# stats.pm $Id$
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
package ninbot::stats;

use strict;
use DBI;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{_BOT} = &main::get_Self;
    $self->{_DBH} = $self->{_BOT}->{_DBH};
    $self->{_BOT}->log( 4, "<Stats> Created new Statistic object" );
    return $self;
}

sub get_global {
	my $stats = shift;
	my $self = $stats->{_BOT};
	my $dbh = $stats->{_DBH};
	my @ret = $dbh->select("stats", "_GLOBAL");
	if (!defined $ret[1]) {
		$self->log(2, "<Stats> No Global Counter found! Created new one!");	
		#create new GLOBAL counter
		my @value = ("_GLOBAL", 0);
		$dbh->add("stats", @value);
		return 0;
	}
	$self->log(4, "<Stats> Found Global Counter ($ret[1])");
	return $ret[1];
}

sub get_name {
	my ( $stats, $name ) = @_;
	my $self = $stats->{_BOT};
	my $dbh = $stats->{_DBH};
	my @ret = $dbh->select("stats", $name);
	if (!defined $ret[1]) {
		#$self->log(2, "<Stats> No Counter '$name' found! Created new one!");	
		#my @value = ($name, 0);
		#$dbh->add("stats", @value);
		$self->log(2, "<Stats> No Counter '$name' found!");
		return 0;
	}
	$self->log(4, "<Stats> Found Counter '$name' ($ret[1])");
	return $ret[1];
}

sub del_name {
	my ( $stats, $name ) = @_;
	my $self = $stats->{_BOT};
	my $dbh = $stats->{_DBH};
	my $ret = $dbh->del("stats", $name);
	return $ret;
}

sub inc_global {
	my $stats = shift;
	my $self = $stats->{_BOT};
	my $dbh = $stats->{_DBH};
	my @ret = $dbh->select("stats", "_GLOBAL");
	if (!defined $ret[1]) {
		$self->log(2, "<Stats> No Global Counter found! Created new one and set to 1!");	
		#create new GLOBAL counter
		my @value = ("_GLOBAL", 1);
		$dbh->add("stats", @value);
	} else {
		my $count = $ret[1];
		$count++;
		$self->log(4, "<Stats> Increment Global Counter ($count)");
		my @value = ("_GLOBAL", $count);
		if ($dbh->update("stats", @value) == -1) {
			$self->log(3, "<Stats> Error on Update Global Counter");
		}
	}
}

sub inc_name {
	my ( $stats, $name ) = @_;
	my $self = $stats->{_BOT};
	my $dbh = $stats->{_DBH};
	my @ret = $dbh->select("stats", $name);
	if (!defined $ret[1]) {
		$self->log(2, "<Stats> No Counter '$name' found! Created new one and set to 1!");	
		my @value = ($name, 1);
		$dbh->add("stats", @value);
		$stats->inc_global if ($name !~ /^irc-/); # increase global on every name
	} else {
		my $count = $ret[1];
		$count++;
		$self->log(4, "<Stats> Increment Counter '$name' ($count)");
		my @value = ($name, $count);
		if ($dbh->update("stats", @value) == -1) {
			$self->log(3, "<Stats> Error on Update Counter for '$name'");
		}
	}
}

1;

