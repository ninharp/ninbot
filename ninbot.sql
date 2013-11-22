CREATE DATABASE ninbot;
USE ninbot;

# DROP TABLE IF EXISTS calc;
CREATE TABLE `calc` (
  `name` varchar(100) NOT NULL default '',
  `value` blob,
  `author` varchar(100) default NULL,
  `time` varchar(100) default NULL,
  `changed` int(11) default NULL,
  `rtb` tinyint(3) unsigned default NULL,
  `flag` char(2) NOT NULL default 'rw',
  `level` tinyint(2) default '0',
  PRIMARY KEY  (`name`)
);

# DROP TABLE IF EXISTS user;
CREATE TABLE `user` (
  `handle` varchar(9) NOT NULL default '0',
  `hosts` blob NOT NULL,
  `flag` tinyint(3) unsigned default '0',
  `password` varchar(128) NOT NULL default '',
  PRIMARY KEY  (`handle`)
);

