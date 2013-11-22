package ninbot::interpreter;
# CalcScript Interpreter Module for ninBOT - http://ninbot.sourceforge.net
# $Header: /cvsroot/ninbot/ninbot/ninbot/interpreter.pm,v 1.1 2003/05/08 10:40:25 prahnin Exp $
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
use Data::Dumper;
use ninbot::script;

# Creates a new script interpreter
sub new {
  my $class = shift;
  my $self = {@_};
  bless ($self, $class);
  $self->{_BOT} = &main::get_Self;
  $self->{disabled} = 0;
  $self->{command_stack} = [];
  $self->{develop} = `sh $self->{_BOT}->{config}->{develop_script}`;
  $self->{_BOT}->log(3, "<Interpreter> Initialized.");
  return $self;
}

# default subroutine for undefined functions
sub AUTOLOAD {
  use vars qw($AUTOLOAD);
  my ($script_self, $do_this, $nick, $chan, $param) = @_;
  my $self = &main::get_Self;
  my $conn = $self->{conn};
  $self->log(5, "<Interpreter> No function by that name: $AUTOLOAD");
}

# routine for module closing
sub DESTROY {
  my $self = &main::get_Self;
  $self->log(3, "<Interpreter> Destroyed.");
}

#### Public Functions

# Parses script
sub parse_Script {
  my ($script_self, $nick, $chan, $script, $level, $param) = @_;
  my $self = &main::get_Self;
  my $calc = $self->{_CALC};
  my $stats = $self->{_STATS};
  my $conn = $self->{conn};
  my $script_obj = ninbot::script::new(
				       '-param' => $param,
				       '-command' => $script_self->{command},
				       '-channel' => $chan,
				       '-nickname' => $nick,
				       '-level' => $level,
				       '_SCRIPT' => $script,
				       '_CONN' => $conn,
				       '_PARENT' => $script_self
				      );

  $script_obj->_parse;
  return;
}

#### Private functions

# pop from a stack
sub _pop_Stack {
  my ($self, $name, $value) = @_;
  my $ret = 0;
  my @stack = @{$self->{stacks}->{$name}} if defined $self->{stacks}->{$name};
  my @newstack;
  if (defined $self->{stacks}->{$name}) {
    foreach my $entry (@stack) {
      push(@newstack, $entry) if $entry ne $value;
      $ret = 1 if $entry eq $value;
    }
    $self->{stacks}->{$name} = \@newstack;
  }
  return $ret;
}

# push to a stack
sub _push_Stack {
  my ($self, $name, $value) = @_;
  my @stack;
  my $double = 0;
  @stack = @{$self->{stacks}->{$name}} if defined $self->{stacks}->{$name};
  foreach (@stack) {
    $double = 1 if $_ =~ m/$value/i;
  }
  push(@stack, $value) if $double == 0;
  $self->{stacks}->{$name} = \@stack;
  return $double;
}

sub _flush_Stack {
  my ($self, $name) = @_;
  delete $self->{stacks}->{$name} if defined $self->{stacks}->{$name};
}

# get the stack
sub _get_Stack {
  my ($self, $name) = @_;
  my @ret;
  @ret = @{$self->{stacks}->{$name}} if defined $self->{stacks}->{$name};
  return @ret;
}

# check in the stack
sub _check_Stack {
  my ($self, $name, $value) = @_;
  my $ret = 0;
  my @stack = @{$self->{stacks}->{$name}} if defined $self->{stacks}->{$name};
  if (defined $self->{stacks}->{$name}) {
    foreach my $entry (@stack) {
      $ret = 1 if $entry eq $value;
    }
  }
  return $ret;
}

sub _get_Var {
  my ($script_self, $var_name) = @_;
  my $self = &main::get_Self;
  my $calc = $self->{_CALC};
  my $ret;
  my @var_calc = $calc->get_Calc($var_name);
  $ret = $var_calc[1] if defined $var_calc[1];
  return $ret;
}

1;
