#!/bin/sh
#####################################
# ninBOT installation script
# 
# $Id: install.sh,v 1.1 2003/04/17 00:27:03 prahnin Exp $
#####################################

BACKTITLE="ninBOT Installation/Configuration Routine";
CONFIG_FILE="ninbot.conf";
PWD=`pwd`;

DEF_SQL_SERVER=`cat $CONFIG_FILE|grep sql_dsn|awk '{ print $2 }'|awk -F ':' '{ print $4 }'`
DEF_SQL_TABLE=`cat $CONFIG_FILE|grep sql_dsn|awk '{ print $2 }'|awk -F ':' '{ print $3 }'`
DEF_SQL_PORT=`cat $CONFIG_FILE|grep sql_dsn|awk '{ print $2 }'|awk -F ':' '{ print $5 }'`
DEF_SQL_USER=`cat $CONFIG_FILE|grep sql_user|awk '{ print $2 }'`
DEF_SQL_PASSWORD=`cat $CONFIG_FILE|grep sql_password|awk '{ print $2 }'`
DEF_BOT_NICKNAME=`cat $CONFIG_FILE|grep irc_nickname|awk '{ print $2 }'`
DEF_BOT_REALNAME=`cat $CONFIG_FILE|grep irc_email|awk '{ print $2 }'`
DEF_BOT_IDENT=`cat $CONFIG_FILE|grep irc_ident|awk '{ print $2 }'`
DEF_IRC_SERVER=`cat $CONFIG_FILE|grep irc_server|awk '{ print $2 }'`
DEF_IRC_PORT=`cat $CONFIG_FILE|grep irc_port|awk '{ print $2 }'`

SQL_FILE="ninbot.sql"

create_sql_tables()
{
    mysql -p$DEF_SQL_PASSWORD -h$DEF_SQL_SERVER -P$DEF_SQL_PORT -u$DEF_SQL_USER -e"CREATE DATABASE $DEF_SQL_TABLE;"
    mysql -p$DEF_SQL_PASSWORD -h$DEF_SQL_SERVER -P$DEF_SQL_PORT -u$DEF_SQL_USER -D$DEF_SQL_TABLE < ninbot.sql
EOF
    return
}

sql_settings() 
{
TITLE="ninBOT SQL Settings";
x=0
while [ $x -eq 0 ]
do
dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "To move [UP/DOWN] arrow keys, [Enter] to Select:" 14 56 6 \
	"SQL Server"           "Sets the SQL Server [$DEF_SQL_SERVER]"\
	"SQL Port"             "Sets the SQL Port [$DEF_SQL_PORT]"\
	"SQL User"             "Sets the SQL User [$DEF_SQL_USER]"\
	"SQL Password"         "Sets the SQL Password [$DEF_SQL_PASSWORD]"\
	"SQL Database"         "Sets the SQL Database [$DEF_SQL_TABLE]"\
	"Create tables"        "Creates empty tables"\
	"Back to Main"         "Back to MainMenu" 2> menuchoice.sqlsettings.$$

retopt=$?

choice=`cat menuchoice.sqlsettings.$$`

rm -f menuchoice.sqlsettings.$$
case $retopt in
    0)
    case $choice in
	"SQL Server")
	    TITLE="SQL Server";
	    TEXT="Please type in the SQL Server Adress:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_SQL_SERVER >/tmp/value.$$ 2>&1;
	    SQL_SERVER=`cat /tmp/value.$$`
	    if [ -n $SQL_SERVER ]; 
		then 
		    DEF_SQL_SERVER=$SQL_SERVER
	    fi
	    ;;
	"SQL Port")
	    TITLE="SQL Port";
	    TEXT="Please type in the SQL Port:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_SQL_PORT >/tmp/value.$$ 2>&1;
	    SQL_PORT=`cat /tmp/value.$$`
	    if [ -n $SQL_PORT ]; 
		then 
		    DEF_SQL_PORT=$SQL_PORT
	    fi
	    ;;
	"SQL User")    
	    TITLE="SQL Username";
	    TEXT="Please type in the SQL Username:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_SQL_USER >/tmp/value.$$ 2>&1;
	    SQL_USER=`cat /tmp/value.$$`
	    if [ -n $SQL_USER ]; 
		then 
		    DEF_SQL_USER=$SQL_USER
	    fi
	    ;;
	"SQL Password")	 
	    TITLE="SQL Password";
	    TEXT="Please type in the SQL Password:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_SQL_PASSWORD >/tmp/value.$$ 2>&1;
	    SQL_PASSWORD=`cat /tmp/value.$$`
	    if [ -n $SQL_PASSWORD ]; 
		then 
		    DEF_SQL_PASSWORD=$SQL_PASSWORD
	    fi
	    ;;
	"SQL Database")
	    TITLE="SQL Table";
	    TEXT="Please type in the SQL Table:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_SQL_TABLE >/tmp/value.$$ 2>&1;
	    SQL_TABLE=`cat /tmp/value.$$`
	    if [ -n $SQL_TABLE ]; 
		then 
		    DEF_SQL_TABLE=$SQL_TABLE
	    fi
	    ;;
	"Create tables")
	    create_sql_tables;;
	"Back to Main") x=1;;
    esac   
    ;;
    1) x=1 ;;
    255) x=1 ;;
esac
done
return
}

irc_settings()
{

TITLE="ninBOT IRC Settings";
x=0
while [ $x -eq 0 ]
do
dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "To move [UP/DOWN] arrow keys, [Enter] to Select:" 14 56 6 \
	"Nickname"           "Sets the nickname [$DEF_BOT_NICKNAME]"\
	"Realname"           "Sets the realname [$DEF_BOT_REALNAME]"\
	"Ident"              "Sets the ident [$DEF_BOT_IDENT]"\
	"IRC Server"         "Sets the default IRC server [$DEF_IRC_SERVER]"\
	"IRC Port"           "Sets the default IRC port [$DEF_IRC_PORT]"\
	"Back to Main"       "Back to MainMenu" 2> menuchoice.ircsettings.$$

retopt=$?

choice=`cat menuchoice.ircsettings.$$`

rm -f menuchoice.ircsettings.$$
case $retopt in
    0)
    case $choice in
	"Nickname")
	    TITLE="Bot Nickname";
	    TEXT="Please type in the nickname for the bot:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_BOT_NICKNAME >/tmp/value.$$ 2>&1;
	    BOT_NICKNAME=`cat /tmp/value.$$`
	    if [ -n $BOT_NICKNAME ]; 
		then 
		    DEF_BOT_NICKNAME=$BOT_NICKNAME
	    fi
	    ;;
	"Realname")
	    TITLE="Bot Realname";
	    TEXT="Please type in the realname for the bot:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_BOT_REALNAME >/tmp/value.$$ 2>&1;
	    BOT_REALNAME=`cat /tmp/value.$$`
	    if [ -n $BOT_REALNAME ]; 
		then 
		    DEF_BOT_REALNAME=$BOT_REALNAME
	    fi
	    ;;
	"Ident")
	    TITLE="Bot Ident";
	    TEXT="Please type in the ident for the bot:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_BOT_IDENT >/tmp/value.$$ 2>&1;
	    BOT_IDENT=`cat /tmp/value.$$`
	    if [ -n $BOT_IDENT ]; 
		then 
		    DEF_BOT_IDENT=$BOT_IDENT
	    fi
	    ;;
	"IRC Server")
	    TITLE="IRC Server";
	    TEXT="Please type in an irc server for the bot (w/o port):";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_IRC_SERVER >/tmp/value.$$ 2>&1;
	    IRC_SERVER=`cat /tmp/value.$$`
	    if [ -n $IRC_SERVER ]; 
		then 
		    DEF_IRC_SERVER=$IRC_SERVER
	    fi
	    ;;
	"IRC Port")
	    TITLE="IRC Port";
	    TEXT="Please type in an default port for irc service:";
	    dialog --backtitle "$BACKTITLE" --title "$TITLE" --inputbox "$TEXT" 10 46 $DEF_IRC_PORT >/tmp/value.$$ 2>&1;
	    IRC_PORT=`cat /tmp/value.$$`
	    if [ -n $IRC_PORT ]; 
		then 
		    DEF_IRC_PORT=$IRC_PORT
	    fi
	    ;;
	"Back to Main") x=1;;
    esac   
    ;;
    1) x=1 ;;
    255) x=1 ;;
esac
done
return
}

data_settings()
{
TITLE="ninBOT Data Settings";
x=0
while [ $x -eq 0 ]
do
dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "To move [UP/DOWN] arrow keys, [Enter] to Select:" 14 56 6 \
	"Create Directories" "Creates the needed Directories"\
	"Create Files"       "Creates the needed Files"\
	"Flush Data"         "Flushes Global/Nick variable cache"\
	"Back to Main"       "Back to MainMenu" 2> menuchoice.datasettings.$$

retopt=$?

choice=`cat menuchoice.datasettings.$$`

rm -f menuchoice.datasettings.$$
case $retopt in
    0)
    case $choice in
	"Create Directories")
	    if [ -d nicks/ ]; 
		then dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nData Directory already exists." 7 60 
	    else 
		mkdir $PWD/data
		dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nData Directory successfully created." 7 60 
	    fi
	    if [ -d nicks/ ]; 
		then  dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nDirectory for 'per nickname' specific variables already exists." 7 60
	    else 
		mkdir $PWD/nicks
		dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nDirectory for 'per nickname' specific variables successfully created." 7 60
	    fi
	    ;;
	"Create Files")
	    touch $PWD/data/bans.db
	    touch $PWD/data/globalvar.db
	    touch $PWD/data/channels.db
	    dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nNeeded files successfully created." 7 60
	    ;;
	"Flush Data")
	    rm -f $PWD/nicks/*
	    rm -f $PWD/data/*
	    touch $PWD/data/bans.db
	    touch $PWD/data/globalvar.db
	    touch $PWD/data/channels.db
	    dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nData Successfully flushed." 7 60
	    ;;
	"Back to Main") x=1;;
    esac   
    ;;
    1) x=1 ;;
    255) x=1 ;;
esac
done
return
}

save_config()
{

echo <<EOF "    banlist_file   data/bans.db
    channel_file   data/channels.db
    command_trigger   !
    daemon   0
    develop_script   lines.sh
    irc_email   $BOT_REALNAME
    irc_ident   $BOT_IDENT
    irc_nickname   $BOT_NICKNAME
    irc_port   $IRC_PORT
    irc_server   $IRC_SERVER
    log_file   ninbot.log
    var_file   data/globalvar.db
    nickvar_dir   nicks/
    pid_file   ninbot.pid
    save_interval   900
    <server>
	1   $IRC_SERVER
    </server>
    sql_dsn   dbi:mysql:$SQL_TABLE:$SQL_SERVER:$SQL_PORT
    sql_password   $SQL_PASSWORD
    sql_user   $SQL_USER" > $CONFIG_FILE
EOF

if [ -s $CONFIG_FILE ]; 
then
    dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nConfiguration successfully saved." 7 60
else
    dialog --backtitle "$BACKTITLE"  --title "Information" --msgbox "\nConfiguration failed saving." 7 60
fi

return
}

TITLE="ninBot Main Menu";
while true
do
dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "To move [UP/DOWN] arrow keys, [Enter] to Select:" 14 56 5 \
        "SQL Settings"       "To change the SQL Settings" \
        "IRC Settings"       "To change the IRC Settings"\
	"Data Settings"      "To change the Data Settings"\
	"Save Config"        "Saves the configuration"\
	"Exit"               "To exit this Program" 2> menuchoice.temp.$$

retopt=$?

choice=`cat menuchoice.temp.$$`

rm -f menuchoice.temp.$$

case $retopt in
    0)
case $choice in
    "SQL Settings") sql_settings ;;
    "IRC Settings") irc_settings ;;
    "Data Settings") data_settings ;;
    "Save Config") save_config ;;
    "Exit") exit 0;;
        esac   
      ;;
     1) exit ;;
     255) exit ;;
 esac
done
clear

