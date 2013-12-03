#####################################################################
#                                                                   #
#   IRC -- Object-oriented Perl interface to an IRC server     #
#                                                                   #
#   IRC.pm: A nifty little wrapper that makes your life easier.     #
#                                                                   #
#          Copyright (c) 1997 Greg Bacon & Dennis Taylor.           #
#                       All rights reserved.                        #
#                                                                   #
#      This module is free software; you can redistribute or        #
#      modify it under the terms of Perl's Artistic License.        #
#                                                                   #
#####################################################################
# $Id$


package IRC;

BEGIN { require 5.004; }    # needs IO::* and $coderef->(@args) syntax 

use IRC::Connection;
use IRC::EventQueue;
use IO::Select;
use Carp;


# grab the drop-in replacement for time() from Time::HiRes, if it's available
BEGIN {
   Time::HiRes->import('time') if eval "require Time::HiRes";
}


use strict;
use vars qw($VERSION);

$VERSION = "0.79";

sub new {
  my $proto = shift;
  
  my $self = {
    '_conn'             => [],
    '_connhash'         => {},
    '_error'            => IO::Select->new(),
    '_debug'            => 0,
    '_schedulequeue'    => new IRC::EventQueue(),
    '_outputqueue'      => new IRC::EventQueue(),
    '_read'             => IO::Select->new(),
    '_timeout'          => 1,
    '_write'            => IO::Select->new(),
  };
  
  bless $self, $proto;
  
  return $self;
}

sub outputqueue {
  my $self = shift;
  return $self->{_outputqueue};
}

sub schedulequeue {
  my $self = shift;
  return $self->{_schedulequeue};
}

# Front end to addfh(), below. Sets it to read by default.
# Takes at least 1 arg:  an object to add to the select loop.
#           (optional)   a flag string to pass to addfh() (see below)
sub addconn {
  my ($self, $conn) = @_;
  
  $self->addfh( $conn->socket, $conn->can('parse'), ($_[2] || 'r'), $conn);
}

# Adds a filehandle to the select loop. Tasty and flavorful.
# Takes 3 args:  a filehandle or socket to add
#                a coderef (can be undef) to pass the ready filehandle to for
#                  user-specified reading/writing/error handling.
#    (optional)  a string with r/w/e flags, similar to C's fopen() syntax,
#                  except that you can combine flags (i.e., "rw").
#    (optional)  an object that the coderef is a method of
sub addfh {
  my ($self, $fh, $code, $flag, $obj) = @_;
  my ($letter);
  
  die "Not enough arguments to IRC->addfh()" unless defined $code;
  
  if ($flag) {
    foreach $letter (split(//, lc $flag)) {
      if ($letter eq 'r') {
        $self->{_read}->add( $fh );
      } elsif ($letter eq 'w') {
        $self->{_write}->add( $fh );
      } elsif ($letter eq 'e') {
        $self->{_error}->add( $fh );
      }
    }
  } else {
    $self->{_read}->add( $fh );
  }
  
  $self->{_connhash}->{$fh} = [ $code, $obj ];
}

# Sets or returns the debugging flag for this object.
# Takes 1 optional arg: a new boolean value for the flag.
sub debug {
  my $self = shift;
  
  if (@_) {
    $self->{_debug} = $_[0];
  }
  return $self->{_debug};
}

# Goes through one iteration of the main event loop. Useful for integrating
# other event-based systems (Tk, etc.) with Net::IRC.
# Takes no args.
sub do_one_loop {
  my $self = shift;
  my ($ev, $sock, $time, $nexttimer, $timeout);
  my (undef, undef, undef, $caller) = caller(1);

  $time = time();             # no use calling time() all the time.

  if(!$self->outputqueue->is_empty) {
    my $outputevent = undef;
    while(defined($outputevent = $self->outputqueue->head)
          && $outputevent->time <= $time) {
      $outputevent = $self->outputqueue->dequeue();
      $outputevent->content->{coderef}->(@{$outputevent->content->{args}});
    }
    $nexttimer = $self->outputqueue->head->time if !$self->outputqueue->is_empty();
  }

  # we don't want to bother waiting on input or running
  # scheduled events if we're just flushing the output queue
  # so we bail out here
  return if $caller eq 'IRC::flush_output_queue';

  # Check the queue for scheduled events to run.
  if(!$self->schedulequeue->is_empty) {
    my $scheduledevent = undef;
    while(defined($scheduledevent = $self->schedulequeue->head) && $scheduledevent->time <= $time) {
      $scheduledevent = $self->schedulequeue->dequeue();
      $scheduledevent->content->{coderef}->(@{$scheduledevent->content->{args}});
    }
    if(!$self->schedulequeue->is_empty()
       && $nexttimer
       && $self->schedulequeue->head->time < $nexttimer) {
      $nexttimer = $self->schedulequeue->head->time;
    }
  }

  # Block until input arrives, then hand the filehandle over to the
  # user-supplied coderef. Look! It's a freezer full of government cheese!
  
  if ($nexttimer) {
    $timeout = $nexttimer - $time < $self->{_timeout}
    ? $nexttimer - $time : $self->{_timeout};
  } else {
    $timeout = $self->{_timeout};
  }
  foreach $ev (IO::Select->select($self->{_read},
                                  $self->{_write},
                                  $self->{_error},
                                  $timeout)) {
    foreach $sock (@{$ev}) {
      my $conn = $self->{_connhash}->{$sock};
      $conn or next;
    
      # $conn->[0] is a code reference to a handler sub.
      # $conn->[1] is optionally an object which the
      #    handler sub may be a method of.
      
      $conn->[0]->($conn->[1] ? ($conn->[1], $sock) : $sock);
    }
  }
}

sub flush_output_queue {
  my $self = shift;

  while(!$self->outputqueue->is_empty()) {
    $self->do_one_loop();
  }
}

# Creates and returns a new Connection object.
# Any args here get passed to Connection->connect().
sub newconn {
  my $self = shift;
  my $conn = IRC::Connection->new($self, @_);
  
  return if $conn->error;
  return $conn;
}

# Takes the args passed to it by Connection->schedule()... see it for details.
sub enqueue_scheduled_event {
  my $self = shift;
  my $time = shift;
  my $coderef = shift;
  my @args = @_;

  return $self->schedulequeue->enqueue($time, { coderef => $coderef, args => \@args });
}

# Takes a scheduled event ID to remove from the queue.
# Returns the deleted coderef, if you actually care.
sub dequeue_scheduled_event {
  my ($self, $id) = @_;
  $self->schedulequeue->dequeue($id);
}

# Takes the args passed to it by Connection->schedule()... see it for details.
sub enqueue_output_event {
  my $self = shift;
  my $time = shift;
  my $coderef = shift;
  my @args = @_;

  return $self->outputqueue->enqueue($time, { coderef => $coderef, args => \@args });
}

# Takes a scheduled event ID to remove from the queue.
# Returns the deleted coderef, if you actually care.
sub dequeue_output_event {
  my ($self, $id) = @_;
  $self->outputqueue->dequeue($id);
}

# Front-end for removefh(), below.
# Takes 1 arg:  a Connection (or DCC or whatever) to remove.
sub removeconn {
  my ($self, $conn) = @_;
  
  $self->removefh( $conn->socket );
}

# Given a filehandle, removes it from all select lists. You get the picture.
sub removefh {
  my ($self, $fh) = @_;
  
  $self->{_read}->remove( $fh );
  $self->{_write}->remove( $fh );
  $self->{_error}->remove( $fh );
  delete $self->{_connhash}->{$fh};
}

# Begin the main loop. Wheee. Hope you remembered to set up your handlers
# first... (takes no args, of course)
sub start {
  my $self = shift;
  
  while (1) {
    $self->do_one_loop();
  }
}

# Sets or returns the current timeout, in seconds, for the select loop.
# Takes 1 optional arg:  the new value for the timeout, in seconds.
# Fractional timeout values are just fine, as per the core select().
sub timeout {
  my $self = shift;
  
  if (@_) { $self->{_timeout} = $_[0] }
  return $self->{_timeout};
}

1;
