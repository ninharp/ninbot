# CalcScript Module for ninBOT - https://github.com/ninharp/ninbot
# script.pm $Id$
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
package ninbot::script;

use strict;
use Data::Dumper;

# Creates a new script object
sub new {
    my $self = {
        '-param'    => '',
        '-return'   => '',
        '-command'  => '',
        '-channel'  => '',
        '-nickname' => '',
        '-level'    => '',
        '_PARENT'   => '',
        '_COUNT'    => 0,
        '_BOT'      => &main::get_Self
    };
    bless($self);
    while ( scalar(@_) >= 2 ) {
        my $name  = shift;
        my $value = shift;
        $self->{$name} = $value;
    }
    $self->{_DEVELOP} = `sh $self->{_BOT}->{config}->{develop_script}`;
    $self->{_BOT}->log( 3,
        "<Script> Script Object loaded! (" . $self->{'-command'} . ")" );
    return $self;
}

# default subroutine for undefined functions
sub AUTOLOAD {
    use vars qw($AUTOLOAD);
    my $self = shift;
    $self->{_BOT}->log( 5, "<Script> No function by that name: $AUTOLOAD" );
}

# routine for module closing
sub DESTROY {
    my $self = shift;
    $self->{_BOT}->log( 3,
        "<Script> Script Object Destroyed. (" . $self->{'-command'} . ")" );
    delete $self->{-param};
    delete $self->{-command};
    delete $self->{-return};
}

sub _parse {
    my $self = shift;
    my $script;
    if ( scalar(@_) > 0 ) {
        $script = shift;
    }
    else {
        $script = $self->{_SCRIPT};
    }

    #print "SCRIPT DEBUG: $script\n\n";
    my @cmds            = split( /;/, $script );
    my $conn            = $self->{_CONN};
    my $inter           = $self->{_PARENT};
    my $calc            = $self->{_BOT}->{_CALC};
    my $nick            = $self->{-nickname};
    my $chan            = $self->{-channel};
    my $trigger_command = $self->{-command};
    my $level           = $self->{-level};
    my $param           = $self->{-param};
    my $bot             = $self->{_BOT};
    my $return          = $self->{-return};
    $param = "" if !defined $param;
    $bot->log( 3, "<Script> Parsing CalcScript! ($trigger_command)[$param]" );

    for ( my $cmd_count = 0 ; $cmd_count < scalar(@cmds) ; $cmd_count++ ) {
        my $com = $cmds[$cmd_count];
        if ( length($com) > 2 ) {
            $com =~ s/^\W*(.*)$/$1/;
            $com =~ m/^(.*?)\s+(.*)$/;
            my $command = lc($1);
            my $do_this = $2;
            $bot->log( 6, "<Script> $command($do_this)" ) if defined $do_this;
            $bot->log( 6, "<Script> $command" )           if !defined $do_this;
            if ( $command =~ m/sleep/i ) {
                if ( $com =~ m/sleep\s*(\d+)/i ) {
                    my $time = $1;
                    my $script_temp;
                    for ( my $i = $cmd_count + 1 ; $i <= scalar(@cmds) ; $i++ )
                    {
                        $script_temp .=
                          $cmds[$i] . ";";    # if defined $cmds[$i+1];
                    }
                    my $after_script = sub {
                        my ( undef, $calc_script ) = @_;
                        $self->_parse($calc_script);
                    };
                    $conn->schedule( $time, $after_script, $script_temp );
                    $bot->log( 3, "<Script> Delay of $time seconds from $nick($level) on $chan"
                    );
                    last;
                }
            }
            ## Debug start
            elsif ( $com =~ m/stackprint\W?\((.*?)\)/i ) {
                my $stack_name = $1;
                my @stack      = $self->_get_Stack($stack_name);
                my $output;
                if ( defined $stack[0] ) {
                    foreach my $entry (@stack) {
                        $output .= $entry . " ";
                    }
                    $conn->privmsg( $chan,
                        "Stack " . $stack_name . ": " . $output );
                }
                else {
                    $conn->privmsg( $chan, "No Stack by that name!" );
                }
            }
            ## Debug end
            elsif ( $com =~ m/randcalc/i ) {
                my @r_calc = $calc->rand_Calc;
                while ( $r_calc[6] !~ m/r/i ) {
                    @r_calc = $calc->rand_Calc;
                }
                my ( $r_name, $r_text, $r_author, $r_date, undef, undef, undef )
                  = @r_calc;
                my $send_text =
                    "* " 
                  . $r_name . " = " 
                  . $r_text . " ["
                  . $r_author . ", "
                  . $r_date . ", "
                  . $r_calc[6] . "/"
                  . $r_calc[7] . "]";
                $conn->privmsg( $chan, $send_text );
            }
            elsif ( $com =~ m/msg\W+(.*?)\W+\"(.*)\"/i ) {
                my $to_nick  = $1;
                my $msg_text = $2;
                $conn->privmsg( $to_nick, $msg_text );
            }
            elsif ( $com =~ m/msg\W+\"(.*)\"/i ) {
                my $to_nick  = $nick;
                my $msg_text = $1;
                $conn->privmsg( $to_nick, $msg_text );
            }
            elsif ( $com =~ m/notice\W+(.*?)\W+\"(.*)\"/i ) {
                my $to_nick     = $1;
                my $notice_text = $2;
                $conn->notice( $to_nick, $notice_text );
            }
            elsif ( $com =~ m/notice\W+\"(.*)\"/i ) {
                my $to_nick     = $nick;
                my $notice_text = $1;
                $conn->notice( $to_nick, $notice_text );
            }
            else {

                #$do_this = $self->_replace_Vars($do_this);
                #print "OLD=$cmd_count\n";
                $self->$command( $do_this, $nick, $chan, $level, $param,
                    \$cmd_count, @cmds );

                #print "NEW=$cmd_count\n";
                #$self->$command($do_this);
            }

            # $cmd_count++;
        }
    }

    #  return;
}

sub _replace_Vars {
    my ( $self, $com ) = @_;
    my $bot     = $self->{_BOT};
    my $inter   = $self->{_PARENT};
    my $nick    = $self->{-nickname};
    my $chan    = $self->{-channel};
    my $level   = $self->{-level};
    my $param   = $self->{-param};
    my $command = $self->{-command};
    my $return  = $self->{-return};
    my $calc    = $bot->{_CALC};
    my $conn    = $self->{_CONN};
    my $develop = $self->{_DEVELOP};
    my @devel   = split( /;;/, $develop );
    my @params  = split( /\ /, $param ) if defined $param;
    $param = "" if !defined $param;
    my $backend = $bot->{config}->{calc_backend};
    $bot->log( 5, "<Script> _replace_Vars = Replacing variables from $nick($level) on $chan [$param]");

    # Replaces some simple values
    $com =~ s/\&nick/$nick/ig;
    $com =~ s/\&version/$bot->{_VERSION}/ig;
    $com =~ s/\&chan/$chan/ig;
    $com =~ s/\&backend/$backend/ig;
    $com =~ s/\&userlevel/$level/ig;
    $com =~ s/\&1/$params[0]/ig if defined $params[0];
    $com =~ s/\&2/$params[1]/ig if defined $params[1];
    $com =~ s/\&3/$params[2]/ig if defined $params[2];
    $com =~ s/\&4/$params[3]/ig if defined $params[3];
    $com =~ s/\&devel\[(\d)\]/$devel[$1]/ig;
    $com =~ s/\&command/$command/ig;
    $com =~ s/\&return/$return/ig;
    $com =~ s/\&allnicks/$bot->{_CHANNEL}->{$chan}->{_NAMES}/ig;

    if ( defined $param and $param ne "" ) {
        $com =~ s/\&param/$param/ig;
        $com =~ s/\&parnick/$param/ig;
    }
    else {
        $com =~ s/\&param//ig;
        $com =~ s/\&parnick/$nick/ig;
    }

    # if_stack(NAME)
    # Returns true if stack NAME is defined
    while ( $com =~ m/if_stack\W?\((.*?)\)/gi ) {
        my $stack_name = $1;
        my @stack      = $inter->_get_Stack($stack_name);
        my $ret        = 0;
        if (@stack) {
            $ret = 1;
        }
        $com =~ s/if_stack\W?\((.*)\)/$ret/i;
    }

    # num_stack(NAME)
    # Returns the number of entries in stack NAME
    while ( $com =~ m/num_stack\W?\((.*?)\)/gi ) {
        my $stack_name = $1;
        my @stack      = $inter->_get_Stack($stack_name);
        my $ret        = 0;
        if (@stack) {
            $ret = scalar(@stack);
        }
        $com =~ s/num_stack\W?\((.*)\)/$ret/i;
    }

    # is_stack(NAME)[VALUE]
    # Returns true if VALUE is included in stack NAME
    while ( $com =~ m/is_stack\W?\((.*?)\)\[(.*?)\]/gi ) {
        my $stack_name  = $1;
        my $stack_value = $2;
        my @stack       = $inter->_get_Stack($stack_name);
        my $ret         = 0;
        if (@stack) {
            foreach my $entry (@stack) {
                $stack_value =~ s/\|/\\\|/g if $stack_value =~ m/\|/;
                if ( $entry =~ m/^$stack_value$/i ) {
                    $ret = 1;
                }
            }
        }
        $com =~ s/is_stack\W?\((.*)\)\[(.*?)\]/$ret/i;
    }

    # stack(NAME)
    # Returns the stack content of the stack NAME
    while ( $com =~ m/stack\W?\((.*?)\)/gi ) {
        my $stack_name = $1;
        my @stack      = $inter->_get_Stack($stack_name);
        my $output;
        my $counter   = 0;
        my $max_stack = scalar(@stack);
        if ( defined $stack[0] ) {
            foreach my $entry (@stack) {
                $output .= $entry;
                if ( defined $stack[ $counter + 2 ] ) {
                    $output .= ", ";
                }
                else {
                    $output .= " und " if defined $stack[ $counter + 1 ];
                }
                $counter++;
            }
            $output =~ s/\\\|/\|/g;
            $com    =~ s/stack\W?\((.*)\)/$output/i;
        }
        else {
            $com =~ s/stack\W?\((.*)\)/<EMPTY>/i;
        }
    }

    # rand_var(NAME)
    # Returns a random entry from the list NAME
    while ( $com =~ m/rand_var\((.*?)\)/gi ) {
        my $var      = $1;
        my $variable = $inter->_get_Var("data-var-$var");
        if ( defined $variable ) {
            my @v_vars   = split( /\@\@/, $variable );
            my $rand_num = int( rand( scalar(@v_vars) ) );
            my $rand_var = $v_vars[$rand_num];
            $self->_replace_Vars($rand_var);
            $com =~ s/rand_var\((.*?)\)/$rand_var/i;
        }
    }
    
    while ( $com =~ m/rand_com/i ) {
		my @r_calc = $calc->rand_com_Calc;
        while ( $r_calc[6] !~ m/r/i ) {
			@r_calc = $calc->rand_com_Calc;
        }
        my ( $r_name, $r_text, $r_author, $r_date, undef, undef, undef ) = @r_calc;
        $r_name =~ s/^com-/$bot->{config}->{command_trigger}/ig;
        $com =~ s/rand_com/$r_name/i;
	}
    
    # rand_com
    # Returns a random command entry
    while ( $com =~ m/rand_var\((.*?)\)/gi ) {
        my $var      = $1;
        my $variable = $inter->_get_Var("data-var-$var");
        if ( defined $variable ) {
            my @v_vars   = split( /\@\@/, $variable );
            my $rand_num = int( rand( scalar(@v_vars) ) );
            my $rand_var = $v_vars[$rand_num];
            $self->_replace_Vars($rand_var);
            $com =~ s/rand_var\((.*?)\)/$rand_var/i;
        }
    }

    # rand_nick
    # Returns a random nickname from the channel
    while ( $com =~ m/rand_nick/gi ) {
        my $nam       = $bot->{_CHANNEL}->{$chan}->{_NAMES};
        my @names     = split( " ", $nam );
        my $rand_num  = int( rand( scalar(@names) ) );
        my $rand_nick = $names[$rand_num];
        $com =~ s/rand_nick/$rand_nick/i;
    }

    # [[NAME]] Parentheses
    # Returns the content of the calc NAME
    while ( $com =~ m/\[\[(.*?)\]\]/gi ) {
        my $calc_name = $1;

        #my @c = $calc->get_Calc("data-var-".$calc_name);
        my @c = $calc->get_Calc($calc_name);
        my $var = $c[1] if defined $c[1];
        $var = $self->_replace_Vars($var) if defined $var;
        $com =~ s/\[\[(.*?)\]\]/$var/gi if defined $var;
    }

    # rand(NUM)
    # Returns a randomized integer from 1 to NUM
    while ( $com =~ m/rand\((.*?)\)/gi ) {
        my $num  = $1;
        my $rand = int( rand($num) ) + 1;
        $com =~ s/rand\((.*?)\)/$rand/i;
    }

    # n_var(NAME)
    # Gets the nick specific variable NAME
    # Could be a list! Accessed with n_var(NAME)[INDEX]
    while ( $com =~ m/n_var\((.*?)\)(\[(.*?)\])?/gi ) {
        my $var = $1;
        my $entry = $2 if defined $2;
        $entry =~ s/^.(.*).$/$1/ if defined $entry;
        my $n_variable = $inter->_get_Var("data-nvar-$nick-$var");
        if ( defined $entry ) {
            if ( defined $n_variable ) {
                my @arr = split( /@@/, $n_variable );
                my $arr_val = $arr[$entry] if defined $arr[$entry] || 0;
                $com =~ s/n_var\((.*?)\)(\[(.*?)\])?/$arr_val/i;
            }
            else {
                $com =~ s/n_var\((.*?)\)(\[(.*?)\])?/0/i;
            }
        }
        else {
            if ( defined $n_variable ) {
                $com =~ s/n_var\((.*?)\)/$n_variable/i;
            }
            else {
                $com =~ s/n_var\((.*?)\)/0/i;
            }
        }
    }

    # var(NAME)
    # Gets the specified variable NAME
    # Could be a list! Accessed with var(NAME)[INDEX]
    while ( $com =~ m/var\((.*?)\)(\[(.*?)\])?/gi ) {
        my $var = $1;
        my $entry = $2 if defined $2;
        $entry =~ s/^.(.*).$/$1/ if defined $entry;
        my $variable = $inter->_get_Var("data-var-$var");
        if ( defined $entry ) {
            if ( defined $variable ) {
                my @arr = split( /@@/, $variable );
                my $arr_val = $arr[$entry] if defined $arr[$entry] || 0;
                $com =~ s/var\((.*?)\)(\[(.*?)\])?/$arr_val/i;
            }
            else {
                $com =~ s/var\((.*?)\)(\[(.*?)\])?/0/i;
            }
        }
        else {
            if ( defined $variable ) {
                $com =~ s/var\((.*?)\)/$variable/i;
            }
            else {
                $com =~ s/var\((.*?)\)/0/i;
            }
        }
    }
    return $com;
}

#### Scripting Functions

sub disable_cmds {
    my ( $script_self, $do_this, $nick, $chan, $level, $param, $cmd_count,
        @cmds )
      = @_;
    my $bot   = $script_self->{_BOT};
    my $inter = $script_self->{_PARENT};
    my $calc  = $bot->{_CALC};
    $inter->{command_disables} = $script_self->{-command};
    my @comcalc = $calc->get_Calc( "data-var-" . $do_this );
    if ( defined $comcalc[1] ) {
        my @dis_com = split( /\s+/, $comcalc[1] );
        foreach (@dis_com) {
            $inter->{disabled_commands}->{$_} = 1;
        }
    }
    $bot->log( 5, "<Script> disable_cmds = Disable commands '$do_this' from $nick($level) on $chan");
}

sub enable_cmds {
    my ( $script_self, $do_this, $nick, $chan, $level, $param, $cmd_count,
        @cmds )
      = @_;
    my $conn  = $script_self->{_CONN};
    my $bot   = $script_self->{_BOT};
    my $inter = $script_self->{_PARENT};
    delete $inter->{command_disables};
    if ( my $disabled = $inter->{disabled_commands} ) {
        my %disabled = %{$disabled};
        foreach ( keys %disabled ) {
            delete $inter->{disabled_commands}->{$_};
        }
    }
    if ( my $c_stack = $inter->{command_stack} ) {
        my @d_cmds = @$c_stack;
        foreach (@d_cmds) {
            my ( $d_type, $d_chan, $d_message ) = split( /:::/, $_ );
            $conn->$d_type( $d_chan, $d_message );
        }
    }
    $inter->{command_stack}     = [];
    $inter->{disabled_commands} = {};
    $bot->log( 5, "<Script> enable_cmds = Enable commands from $nick($level) on $chan");
}

sub run {
    my ( $script_self, $do_this, $nick, $chan, $level, $param, $cmd_count,
        @cmds )
      = @_;
    my $self = &main::get_Self;
    my $conn = $self->{conn};
    my $calc = $self->{_CALC};
    $do_this =~ s/^"(.*)"$/$1/;
    $do_this =~ s/\s/_/g;
    my @run_calc = $calc->get_Calc( "data-prg-" . $do_this );
    if ( defined $run_calc[1] ) {

        if ( $level >= $run_calc[7] or $nick = $run_calc[2] ) {
            my $ret = $script_self->_parse( $run_calc[1] );
        }
    }
    $self->log( 5, "Script Module: run = Run subroutine data-prg-$do_this from $nick($level) on $chan");
}

sub cmd {
    my ( $script_self, $do_this, $nick, $chan, $level, $param, $cmd_count,
        @cmds )
      = @_;
    my $self = &main::get_Self;
    my $conn = $self->{conn};
    my $calc = $self->{_CALC};
    $do_this =~ s/^"(.*)"$/$1/;
    $do_this =~ s/\s/_/g;
    my @run_calc = $calc->get_Calc( "com-" . $do_this );
    if ( defined $run_calc[1] ) {

        if ( $level >= $run_calc[7] or $nick = $run_calc[2] ) {
            my $ret = $script_self->_parse( $run_calc[1] );
        }
    }
    $self->log( 5, "<Script> cmd = Run command com-$do_this from $nick($level) on $chan" );
}

sub nif {
    my ( $self, $do_this, $nick, $chan, $level, $param, $cmd_count, @cmds ) = @_;
    my $conn        = $self->{_CONN};
    my $bot         = $self->{_BOT};
    my $count       = ${$cmd_count};
    my $if_script   = "";
    my $else_script = "";
    my $else        = 0;
    my $then        = 0;
    my $choose      = 1;
    my $ifend       = 0;
    if ( $do_this =~ m/^\s*(.*?)\s*((?:=|eq|\!=|ne))\s*(.*?)$/i ) {
        my ( $if_first, $if_operator, $if_second ) = ( $1, $2, $3 );
        $if_first  = $self->_replace_Vars($if_first);
        $if_second = $self->_replace_Vars($if_second);
        $if_first  =~ s/^"(.*)"$/$1/;
        $if_second =~ s/^"(.*)"$/$1/;
        for ( my $i = $count ; $i < scalar(@cmds) ; $i++ ) {
            if ( $cmds[$i] =~ m/then/i ) {
                $then = 1;
                $cmds[$i] =~ s/then\s*//i;
            }
            if ( $then == 1 ) {
                if ( $cmds[$i] =~ m/fi/i ) {
                    $ifend = $i;

                    # last;
                }
                if ( $else == 0 ) {
                    if ( $cmds[$i] =~ m/else/i ) {
                        $else = 1;
                        $cmds[$i] =~ s/else\s*//i;
                        $else_script .= $cmds[$i] . ";";
                    }
                    else {

                        #$cmds[$i] =~ s/else\s*//i;
                        $if_script .= $cmds[$i] . ";";
                    }
                }
                else {
                    $else_script .= $cmds[$i] . ";";
                }
            }
        }

        #print "ifblaaah: $if_script<-\n";
        #print "elsebluuup: $else_script<-\n";
        # If itself
        if ( $if_operator =~ m/^(?:=|eq)$/i ) {
            print "IF: <$if_first> equals <$if_second> then do <$if_script>\n";
            if ( $if_first eq $if_second ) {
                $choose = 1;
            }
            else {
                $choose = 0;
            }
        }
        elsif ( $if_operator =~ m/^(?:\!=|ne)$/i ) {

        #print "IF: <$if_first> not equals <$if_second> then do <$if_script>\n";
            if ( $if_first ne $if_second ) {
                $choose = 1;
            }
            else {
                $choose = 0;
            }
        }
        else {
            $self->log( 4, "<SCRIPT> IF: Unknown operator! ($if_operator)" );
        }
        if ( $choose == 1 ) {
            $self->_parse($if_script);
        }
        else {
            $self->_parse($else_script);
        }

		#print "-----> $choose-$ifend IF= $do_this <-> $if_script <-> $else_script\n\n";
        $count = $ifend if $ifend != 0;
        $count = scalar(@cmds)
          if $ifend == 0;    #$self->{_COUNT} = scalar(@cmds) if $ifend == 0;
        ${$cmd_count} = $count;
    }
    else {
        print "Wrong IF Syntax\n";
    }
}

# if WHAT OPERATOR WHAT then COMMAND - if statement
sub if {
    my ( $script_self, $do_this, $nick, $chan, $level, $param, $cmd_count,
        @cmds )
      = @_;
    my $self  = &main::get_Self;
    my $conn  = $script_self->{_CONN};
    my $bot   = $script_self->{_BOT};
    my $count = $script_self->{_COUNT};

#  print "Script: ".join("; ", @cmds)."\n";
#  if (join(";", @cmds) =~ m/else/i) {
#    print $count." block detected\n";
#    print $cmds[$count]."\n";
#  }
# while schleife commands bis nen else falls nen else drinne iss und mit den {} mal gucken vielleicht weglassen iss besser wegen allg {}
# mal schauen
#  if ($do_this =~ m/^(\")?.*?(\")?\W?((=)?=|eq|ne|\!=)\W?then\ \w+$/) {
    if ( $do_this =~
m/^\s*(.*?)\s*((?:=|eq|\!=|ne))\s*(.*?)\s+then\s+\{?(.*?)\}?\s*(else\s+\{?(.*)\}?)?$/i
      )
    {
        my ( $if_first, $if_operator, $if_second, $if_script, $if_else ) =
          ( $1, $2, $3, $4, $6 );
        $self->log( 4, "<Script> IF: Correct Syntax <$do_this>" );
        my @if_script_cmds = split( /\:,/, $if_script );
        my @if_else_cmds   = split( /\:,/, $if_else );
        $if_script = join( ";", @if_script_cmds );
        undef @if_script_cmds;
        $if_else = join( ";", @if_else_cmds );
        undef @if_else_cmds;
        $if_script =~ s/^\s*(.*)\s*$/$1/;
        $self->log( 5,
            "IF: <$if_first> $if_operator <$if_second> then <$if_script>" );
        $if_first  = $script_self->_replace_Vars($if_first);
        $if_second = $script_self->_replace_Vars($if_second);
        $if_first  =~ s/^"(.*)"$/$1/;
        $if_second =~ s/^"(.*)"$/$1/;

        if ( $if_operator =~ m/^(?:=|eq)$/i ) {
            $self->log( 5, "<Script> IF: <$if_first> equals <$if_second> then do <$if_script>");
            if ( $if_first eq $if_second ) {
                $self->log( 4, "<Script> IF: It is equal! Starting Script!" );
                $script_self->_parse($if_script);
            }
            else {
                if ( defined $if_else ) {
                    $self->log( 4, "<Script> IF: It is not equal! Starting else Script!" );
                    $script_self->_parse($if_else);
                }
            }
        }
        elsif ( $if_operator =~ m/^(?:\!=|ne)$/i ) {
            $self->log( 5,
"<Script> IF: <$if_first> not equals <$if_second> then do <$if_script>"
            );
            if ( $if_first ne $if_second ) {
                $self->log( 4, "IF: It is not equal! Starting Script!" );
                $script_self->_parse($if_script);
            }
            else {
                if ( defined $if_else ) {
                    $self->log( 4, "<Script> IF: It is not equal! Starting else Script!" );
                    $script_self->_parse($if_else);
                }
            }
        }
        else {
            $self->log( 3, "<Script> IF: Unknown operator! ($if_operator)" );
        }
    }
    else {
        $self->log( 3, "<Script> IF: Wrong syntax!" );
    }
    $script_self->{_COUNT}++;
    $self->log( 5, "<Script> IF: If from $nick($level) on $chan" );
}

# say "WHAT" - says WHAT to actual channel
sub say {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $conn    = $script_self->{_CONN};
    my $bot     = $script_self->{_BOT};
    my $inter   = $script_self->{_PARENT};
    my $command = $script_self->{-command};
    my $dissed  = 0;
    $do_this =~ s/^\s*(.*)\s*/$1/;
    $do_this =~ s/^"(.*)"$/$1/;
    $do_this = $script_self->_replace_Vars($do_this);

    if ( defined $inter->{disabled_commands}->{$command} ) {
        if ( $inter->{command_disables} !~ m/$command/i ) {
            $dissed = 1;
        }
    }
    if ( $dissed == 1 ) {
        my @command_stack;
        if ( defined $inter->{command_stack} ) {
            @command_stack = @{ $inter->{command_stack} };
        }
        CORE::push( @command_stack, "privmsg:::" . $chan . ":::" . $do_this );
        $inter->{command_stack} = \@command_stack;
        $bot->log( 5, "<Script> say = Delayed PrivMsg '$do_this' from $nick($level) to $chan");
    }
    else {
        $conn->privmsg( $chan, $do_this );
        $bot->log( 5, "<Script> say = PrivMsg '$do_this' from $nick($level) to $chan" );
    }
}

# me "WHAT" - does an action WHAT to actual channel
sub me {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $conn     = $script_self->{_CONN};
    my $bot      = $script_self->{_BOT};
    my $inter    = $script_self->{_PARENT};
    my $command  = $script_self->{-command};
    my $disabled = 0;
    $do_this =~ s/^\s*(.*)\s*/$1/;
    $do_this =~ s/^"(.*)"$/$1/;
    $do_this = $script_self->_replace_Vars($do_this);

    if ( defined $inter->{disabled_commands}->{$command} ) {
        if ( $inter->{command_disables} !~ m/$command/i ) {
            $disabled = 1;
        }
    }
    if ( $disabled == 1 ) {
        my @command_stack;
        if ( defined $inter->{command_stack} ) {
            @command_stack = @{ $inter->{command_stack} };
        }
        CORE::push( @command_stack, "me:::" . $chan . ":::" . $do_this );
        $inter->{command_stack} = \@command_stack;
        $bot->log( 5, "<Script> me = Delayed Action '$do_this' from $nick($level) to $chan" );
    }
    else {
        $conn->me( $chan, $do_this );
        $bot->log( 5, "<Script> me = Action '$do_this' from $nick($level) to $chan" );
    }
}

sub return {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self = &main::get_Self;
    my $conn = $self->{conn};
    $do_this =~ s/^\s*(.*)\s*/$1/;
    $do_this =~ s/^"(.*)"$/$1/;
    $do_this = $script_self->_replace_Vars($do_this);
    $script_self->{-return} = $do_this;
    $self->log( 5, "<Script> return = Returns value '$do_this' from $nick($level) on $chan" );
}

sub set {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self       = &main::get_Self;
    my $conn       = $self->{conn};
    my $calc       = $self->{_CALC};
    my $authorized = 1;
    my $set_name;
    if ( $do_this =~ m/^(.*?)\s*=\s*(.*)$/i ) {
        $set_name = $1;
        my $set_value = $2;
        if ( $set_name =~ m/^&param$/i ) {
            $self->log( 5, "<Script> set = Replacing current command parameter!" );
            $authorized = 2;
            $set_value =~ s/^"(.*)"$/$1/;
            $script_self->{-param} = $set_value;
        }
        else {

            #      $set_name = $script_self->_replace_Vars($set_name);
            $set_name = "data-var-".$set_name;
            $set_name  =~ s/^"(.*)"$/$1/;
            $set_value =~ s/^"(.*)"$/$1/;
            my @set_calc   = $calc->get_Calc($set_name);
            my $set_author = $nick;
            if ( $set_calc[1] ) {
                $set_author = $set_calc[2];
                if ( $level < $set_calc[7] or $set_calc[2] !~ m/^$nick$/ ) {
                    $authorized = 0;
                }
            }
            if ($authorized) {
                $calc->del_Calc($set_name);
                $calc->add_Calc( $set_name, $set_author, 0, "rw", $set_value );
            }
        }
    }
    $self->log( 5, "<Script> set = Set variable $set_name from $nick($level) on $chan: $authorized" );
}

sub inc {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self       = &main::get_Self;
    my $conn       = $self->{conn};
    my $calc       = $self->{_CALC};
    my $authorized = 1;
    $do_this = $script_self->_replace_Vars($do_this);
    if ( $do_this =~ m/^(.*)$/i ) {
        my $inc_name  = "data-var-" . $1;
        my $inc_value = 1;
        $inc_name =~ s/^"(.*)"$/$1/;
        my @inc_calc   = $calc->get_Calc($inc_name);
        my $inc_author = $nick;
        if ( $inc_calc[1] ) {
            $inc_author = $inc_calc[2];
            $inc_value  = $inc_calc[1];
            $inc_value++;
            if ( $level < $inc_calc[7] or $inc_calc[6] !~ m/^rw$/i ) {
                $authorized = 0;
            }
        }
        if ($authorized) {
            $calc->del_Calc($inc_name);
            $calc->add_Calc( $inc_name, $inc_author, 0, "rw", $inc_value );
        }
    }
    $self->log( 5, "<Script> inc = Increases variable from $nick($level) on $chan: $authorized" );
}

sub n_inc {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self       = &main::get_Self;
    my $conn       = $self->{conn};
    my $calc       = $self->{_CALC};
    my $authorized = 1;
    my $inc_name;
    $do_this = $script_self->_replace_Vars($do_this);
    if ( $do_this =~ m/^(.*)$/i ) {
        $inc_name = "data-nvar-$nick-" . $1;
        my $inc_value = 1;
        $inc_name =~ s/^"(.*)"$/$1/;
        my @inc_calc   = $calc->get_Calc($inc_name);
        my $inc_author = $nick;
        if ( $inc_calc[1] ) {
            $inc_author = $inc_calc[2];
            $inc_value  = $inc_calc[1];
            $inc_value++;
            if ( $level < $inc_calc[7] or $inc_calc[6] !~ m/^rw$/i ) {
                $authorized = 0;
            }
        }
        if ($authorized) {
            $calc->del_Calc($inc_name);
            $calc->add_Calc( $inc_name, $inc_author, 0, "rw", $inc_value );
        }
    }
    $self->log( 5, "<Script> n_inc = Increases nick variable $inc_name from $nick($level) on $chan: $authorized" );
}

sub s_flush {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self  = $script_self->{_BOT};
    my $inter = $script_self->{_PARENT};
    if ( $do_this =~ m/^(.*)$/i ) {
        my $stack_name = $1;
        $inter->_flush_Stack($stack_name);
        $self->log( 5, "<Script> s_flush = Flush stack $stack_name" );
    }
}

sub pop {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self  = $script_self->{_BOT};
    my $inter = $script_self->{_PARENT};
    $do_this = $script_self->_replace_Vars($do_this);
    $do_this =~ s/\|/\\\|/g if $do_this =~ m/\|/;
    if ( $do_this =~ m/^(.*?)\s*=\s*(.*)$/i ) {
        my $stack_name  = $1;
        my $stack_value = $2;
        $inter->_pop_Stack( $stack_name, $stack_value );
        $self->log( 5, "<Script> pop = Pop $stack_value from $stack_name" );
    }
}

sub push {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self  = $script_self->{_BOT};
    my $inter = $script_self->{_PARENT};
    $do_this = $script_self->_replace_Vars($do_this);
    $do_this =~ s/\|/\\\|/g if $do_this =~ m/\|/;
    if ( $do_this =~ m/^(.*?)\s*=\s*(.*)$/i ) {
        my $stack_name  = $1;
        my $stack_value = $2;
        $stack_name  =~ s/^"(.*)"$/$1/;
        $stack_value =~ s/^"(.*)"$/$1/;
        $self->log( 5, "<Script> push = Push $stack_value to $stack_name" );
        $inter->_push_Stack( $stack_name, $stack_value );
    }
}

sub dec {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self       = &main::get_Self;
    my $conn       = $self->{conn};
    my $calc       = $self->{_CALC};
    my $authorized = 1;
    my $dec_name;
    $do_this = $script_self->_replace_Vars($do_this);
    if ( $do_this =~ m/^(.*)$/i ) {
        $dec_name = "data-var-" . $1;
        my $dec_value = 0;
        $dec_name =~ s/^"(.*)"$/$1/;
        my @dec_calc   = $calc->get_Calc($dec_name);
        my $dec_author = $nick;
        if ( $dec_calc[1] ) {
            $dec_author = $dec_calc[2];
            $dec_value  = $dec_calc[1];
            $dec_value--;
            if ( $level < $dec_calc[7] or $dec_calc[6] !~ m/^rw$/i ) {
                $authorized = 0;
            }
        }
        if ($authorized) {
            $calc->del_Calc($dec_name);
            $calc->add_Calc( $dec_name, $dec_author, 0, "rw", $dec_value );
        }
    }
    $self->log( 5, "<Script> dec = Decreases variable $dec_name from $nick($level) on $chan: $authorized" );
}

sub n_dec {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self       = &main::get_Self;
    my $conn       = $self->{conn};
    my $calc       = $self->{_CALC};
    my $authorized = 1;
    my $dec_name;
    $do_this = $script_self->_replace_Vars($do_this);
    if ( $do_this =~ m/^(.*)$/i ) {
        $dec_name = "data-nvar-$nick-" . $1;
        my $dec_value = 0;
        $dec_name =~ s/^"(.*)"$/$1/;
        my @dec_calc   = $calc->get_Calc($dec_name);
        my $dec_author = $nick;
        if ( $dec_calc[1] ) {
            $dec_author = $dec_calc[2];
            $dec_value  = $dec_calc[1];
            $dec_value--;
            if ( $level < $dec_calc[7] or $dec_calc[6] !~ m/^rw$/i ) {
                $authorized = 0;
            }
        }
        if ($authorized) {
            $calc->del_Calc($dec_name);
            $calc->add_Calc( $dec_name, $dec_author, 0, "rw", $dec_value );
        }
    }
    $self->log( 5, "<Script> n_dec = Decrease nick variable $dec_name from $nick($level) on $chan: $authorized" );
}

sub n_set {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self       = &main::get_Self;
    my $conn       = $self->{conn};
    my $calc       = $self->{_CALC};
    my $authorized = 1;
    my $set_name;
    $do_this = $script_self->_replace_Vars($do_this);
    if ( $do_this =~ m/^(.*?)\s*=\s*(.*)$/i ) {
        $set_name = "data-nvar-$nick-" . $1;
        my $set_value = $2;
        $set_name  =~ s/^"(.*)"$/$1/;
        $set_value =~ s/^"(.*)"$/$1/;
        my @set_calc   = $calc->get_Calc($set_name);
        my $set_author = $nick;
        if ( $set_calc[1] ) {
            $set_author = $set_calc[2];
            if ( $level < $set_calc[7] or $set_calc[2] !~ m/^$nick$/ ) {
                $authorized = 0;
            }
        }
        if ($authorized) {
            $calc->del_Calc($set_name);
            $calc->add_Calc( $set_name, $set_author, 0, "rw", $set_value );
        }
    }
    $self->log( 5, "<Script> n_set = Set nick variable $set_name from $nick($level) on $chan: $authorized" );
}

# part channel
sub part {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self = &main::get_Self;
    my $conn = $self->{conn};
    $do_this = $script_self->_replace_Vars($do_this);
    $conn->part($do_this);
    $self->log( 5, "<Script> part = Parting channel $do_this from $nick($level) on $chan" );
}

# kick user
sub kick {
    my ( $script_self, $do_this, $nick, $chan, $level, $param ) = @_;
    my $self = &main::get_Self;
    my $conn = $self->{conn};
    $do_this = $script_self->_replace_Vars($do_this);
    my ( $k_nick, $k_msg ) = split( /\ /, $do_this );
    $conn->sl("KICK $chan $k_nick :$k_msg");
    $self->log( 5, "<Script> kick = Kicking $nick from channel $chan with message $do_this " );
}

1;
