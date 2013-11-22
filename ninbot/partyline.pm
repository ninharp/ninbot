package ninbot::partyline;

# Partyline Module for ninBOT - https://github.com/ninharp/ninbot
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
use POSIX;
use IO::Socket;
use IO::Socket::INET;
use IO::Select;
use Socket;
use Fcntl;
use Tie::RefHash;
use strict;
use IO::Handle;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self  = {@_};
    bless( $self, $class );
    $self->{inbuffer}   = ();
    $self->{outbuffer}  = ();
    $self->{ready}      = ();
    $self->{authorized} = ();
    $self->{connected}  = { "ficker" => "dsfdfsdfsfsd" };
    return $self;
}

# handle($socket) deals with all pending requests for $client
sub handle {

    # requests are in $ready{$client}
    # send output to $outbuffer{$client}
    my $partyline = shift;
    my $client    = shift;
    my $self      = &main::get_Self;
    my $user      = $self->{_USER};
    foreach my $request ( @{ $partyline->{ready}->{$client} } ) {
        chop($request);
        $request =~ s/\r//g;
        if ( !defined $partyline->{authorized}->{$client} ) {
            my $login = $request;
            $partyline->{authorized}->{$client}->{status} = 1;
            $partyline->{authorized}->{$client}->{login}  = $login;
            $partyline->{outbuffer}->{$client}            = "Password:\r\n";
            print "(System) Login from $login\n";
        }
        elsif ( $partyline->{authorized}->{$client}->{status} == 1 ) {
            my $password = $request;
            $partyline->{authorized}->{$client}->{status} = 2;
            $partyline->{authorized}->{$client}->{log}    = 1;
            $partyline->{authorized}->{$client}->{level}  = 5;
            $partyline->{connected}
              ->{ $partyline->{authorized}->{$client}->{login} } = $client;
            $partyline->{outbuffer}->{$client} =
              $partyline->{authorized}->{$client}->{login}
              . " you have succesfully identified to the partyline.\r\n";
        }
        elsif ( $partyline->{authorized}->{$client}->{status} >= 2 ) {
            print "("
              . $partyline->{authorized}->{$client}->{login} . ") "
              . $request . "\n"
              if $request !~ m/^\W*$/i;
            my $clients = $partyline->{authorized};
            my %clients = %{$clients};
            my $echo    = 1;
            foreach my $c ( keys %clients ) {
                if ( $c ne $client or $echo == 1 ) {
                    $partyline->{outbuffer}->{$c} = "<"
                      . $partyline->{authorized}->{$client}->{login} . "> "
                      . $request . "\r\n"
                      if $request !~ m/^\W*$/i;
                }
            }
        }
        else {
            print "(non authoritive) " . $request;
        }

        # $request is the text of the request
        # put text of reply into $outbuffer{$client}
    }
    delete $partyline->{ready}->{$client};
}

# nonblock($socket) puts socket into nonblocking mode
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

sub nonblock {
    my $partyline = shift;
    my $socket    = shift;
    my $flags     = fcntl( $socket, F_GETFL, 0 ) if defined $socket;
    fcntl( $socket, F_SETFL, $flags | O_NONBLOCK )
      if defined $socket and $flags;
}

# quits the client
sub quit_Client {
    my $partyline = shift;
    my $client    = shift;
    print "Client disconnected!\n";
    delete $partyline->{inbuffer}->{$client};
    delete $partyline->{outbuffer}->{$client};
    delete $partyline->{ready}->{$client};
    $partyline->{_SELECT}->remove($client);
    close($client);
}

sub get_Connected {
    my $partyline = shift;
    my $connected = $partyline->{connected};
    my @ret;
    foreach my $login ( keys %{$connected} ) {
        push( @ret, $login );
    }
    return @ret;
}

# return loggers
sub get_Loggers {
    my $self      = &main::get_Self;
    my $partyline = shift;
    my $level     = shift;
    my @ret;

#  my %clients = %{$partyline->{authorized}};
#  foreach my $c (keys %clients) {
#    if ($partyline->{authorized}->{$c}->{log} and $partyline->{authorized}->{$c}->{level} <= $level) {
#      push(@ret, $c);
#    }
#  }
#  return @ret;
}

sub create_Server {
    my $self       = &main::get_Self;
    my $partyline2 = shift;
    my $partyline  = $self->{_PARTYLINE};
    my $port       = 3333;
    print "Trying to start Partyline Server...";
    while ( !$partyline->{_SERVER} ) {
        $partyline->{_SERVER} = IO::Socket::INET->new(
            LocalAddr => "mokka",
            LocalPort => $port,
            Listen    => 10
        );
        $port++ if ( !$partyline->{_SERVER} );
    }
    print "Listening on port $port.\n";

    #$partyline->{_SL} = IO::Select->new();
    #my $sl = $partyline->{_SL};
    #$sl->add(*READER);
    my $server = $partyline->{_SERVER};
    $partyline->nonblock($server);
    $partyline->{_SELECT} = IO::Select->new($server);

    if ( ( my $c_pid = fork ) != 0 ) {

        #     $self->log(3, "Forked Partyline Server! ($c_pid)");
        my $select = $partyline->{_SELECT};
        while (1) {
            my $client;
            my $rv;
            my $data;

            # check for new information on the connections we have
            # anything to read or accept?
            foreach my $client ( $select->can_read(1) ) {
                if ( $client == $server ) {

                    # accept a new connection
                    $client = $server->accept();
                    print "Accepted connection from "
                      . $client->peerhost() . ":"
                      . $client->peerport() . "\n";
                    $select->add($client);
                    $partyline->nonblock($client);

                #$partyline->{outbuffer}->{$client} = $partyline->{prompt}."\n";
                    $partyline->{outbuffer}->{$client} = "Login: \r\n";
                }
                else {

                    # read data
                    $data = '';
                    $rv = $client->recv( $data, POSIX::BUFSIZ, 0 );
                    unless ( defined($rv) && length $data ) {

                        # This would be the end of file, so close the client
                        delete $partyline->{inbuffer}->{$client};
                        delete $partyline->{outbuffer}->{$client};
                        delete $partyline->{ready}->{$client};

                        #		delete $partyline->{authorized}->{$client};
                        #		delete $partyline->{log}->{$client};
                        $select->remove($client);
                        close $client;
                        next;
                    }
                    $partyline->{inbuffer}->{$client} .= $data;

                    # test whether the data in the buffer or the data we
                    # just read means there is a complete request waiting
                    # to be fulfilled.  If there is, set $ready{$client}
                    # to the requests waiting to be fulfilled.
                    while ( $partyline->{inbuffer}->{$client} =~ s/(.*\n)// ) {
                        push( @{ $partyline->{ready}->{$client} }, $1 );
                    }
                }
            }

            # Any complete requests to process?
            foreach my $client ( keys %{ $partyline->{ready} } ) {

                # print "Handle input for client\n";
                #print $partyline->get_Loggers;
                $partyline->handle($client);
            }

            # Buffers to flush?
            foreach my $client ( $select->can_write(1) ) {

                # Skip this client if we have nothing to say
                next unless exists $partyline->{outbuffer}->{$client};

                # print "Handle output for client\n";
                $rv = $client->send( $partyline->{outbuffer}->{$client}, 0 );
                unless ( defined $rv ) {

                    # Whine, but move on.
                    warn "I was told I could write, but I can't.\n";
                    next;
                }
                if (   $rv == length $partyline->{outbuffer}->{$client}
                    || $! == POSIX::EWOULDBLOCK )
                {
                    substr( $partyline->{outbuffer}{$client}, 0, $rv ) = '';
                    delete $partyline->{outbuffer}->{$client}
                      unless length $partyline->{outbuffer}->{$client};
                }
                else {

                    # Couldn't write all the data, and it wasn't because
                    # it would have blocked.  Shutdown and move on.
                    delete $partyline->{inbuffer}->{$client};
                    delete $partyline->{outbuffer}->{$client};
                    delete $partyline->{ready}->{$client};

                    $select->remove($client);
                    close($client);
                    next;
                }
            }

            # Out of band data?
            foreach my $client ( $select->has_exception(0) ) {  # arg is timeout
                    # Deal with out-of-band data here, if you want to.
            }
        }
    }    # parent
    else {
        print "cannot fork partyline: $!" unless defined $c_pid;
    }
    my $pid = $$;
    return $pid;
}

1;

