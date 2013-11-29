#!/usr/bin/perl -w

use strict;
use DBI;
use CGI qw(:standard);

my ($dsn,$sql_user,$sql_pass) = 0;
$dsn = "dbi:mysql:ninbot:localhost:3306";
$sql_user = "ninbot";
$sql_pass = "password";

my $dbh = DBI->connect($dsn, $sql_user, $sql_pass);

#require('config.pl');

sub show_calc() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Calc DB Editor');
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Dataname</b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b>Autor</b></td>
			<td align="center"><b>Datum</b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="8"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name NOT REGEXP '(^data-)|(^com-)'");
	if ( $sth->execute ) {
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			my $nr = $row[0];
			my $name = $row[1];
			my $value = $row[2];
			my $author = $row[3];
			my $time = $row[4];
			my $changed = $row[5];
			my $flag = $row[6];
			my $level = $row[7];
			print '<tr>
				<td width="2%">'.$nr.'</td>
				<td width="10%" align="center"><i>'.$name.'</i></td>
				<td width="54%" style="background: #eeeeee;">'.$value.'</td>
				<td width="4%";>'.$author.'</td>
				<td width="18%">'.$time.'</td>
				<td width="2%">'.$flag.'</td>
				<td width="2%">'.$level.'</td>
				<td width="8%"><a href="">E</a>/<a href="">D</a></td>
				</tr>
				<tr><td colspan="8"><hr></td></tr>';
		}
	}
	$sth->finish();
	print "</table>";
	print end_html;

}

sub show_data() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Data Variable DB Editor');
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Dataname</b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b>Autor</b></td>
			<td align="center"><b>Datum</b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="8"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^data-'");
	if ( $sth->execute ) {
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			my $nr = $row[0];
			my $name = $row[1];
			my $value = $row[2];
			my $author = $row[3];
			my $time = $row[4];
			my $changed = $row[5];
			my $flag = $row[6];
			my $level = $row[7];
			if ($row[1] !~ m/^data-.?var/i) {
				print '<tr>
				<td width="2%">'.$nr.'</td>
				<td width="10%" align="center"><i>'.$name.'</i></td>
				<td width="54%" style="background: #eeeeee;">'.$value.'</td>
				<td width="4%";>'.$author.'</td>
				<td width="18%">'.$time.'</td>
				<td width="2%">'.$flag.'</td>
				<td width="2%">'.$level.'</td>
				<td width="8%"><a href="">E</a>/<a href="">D</a></td>
				</tr>
				<tr><td colspan="8"><hr></td></tr>';
			}
		}
	}
	print "</table>";
	print end_html;

}

sub show_nvar() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Data Variable DB Editor');
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Variablenname</b></td>
			<td align="center"><b>Dataname</b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b>Autor</b></td>
			<td align="center"><b>Datum</b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="9"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^data-nvar-'");
	if ( $sth->execute ) {
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			my $nr = $row[0];
			my $name = $row[1];
			my $value = $row[2];
			my $author = $row[3];
			my $time = $row[4];
			my $changed = $row[5];
			my $flag = $row[6];
			my $level = $row[7];
			my $vname = "";
			if ($name =~ m/^data-nvar-(.*)/) { $vname = $1; };
			print '<tr>
				<td width="2%">'.$nr.'</td>
				<td width="10%" align="center"><b>'.$name.'</b></td>
				<td width="10%" align="center"><i>'.$name.'</i></td>
				<td width="54%" style="background: #eeeeee;">'.$value.'</td>
				<td width="4%";>'.$author.'</td>
				<td width="18%">'.$time.'</td>
				<td width="2%">'.$flag.'</td>
				<td width="2%">'.$level.'</td>
				<td width="8%"><a href="">E</a>/<a href="">D</a></td>
				</tr>
				<tr><td colspan="9"><hr></td></tr>';
		}
	}
	print "</table>";
	print end_html;

}

sub show_var() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Data Variable DB Editor');
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Variablenname</b></td>
			<td align="center"><b>Dataname</b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b>Autor</b></td>
			<td align="center"><b>Datum</b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="9"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^data-var-'");
	if ( $sth->execute ) {
		my $counter = 1;
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			my $nr = $row[0];
			my $name = $row[1];
			my $value = $row[2];
			my $author = $row[3];
			my $time = $row[4];
			my $changed = $row[5];
			my $flag = $row[6];
			my $level = $row[7];
			my $vname = "";
			if ($name =~ m/^data-var-(.*)/) { $vname = $1; };
			print '<tr>
				<td width="2%">'.$nr.'</td>
				<td width="10%" align="center"><b>'.$vname.'</b></td>
				<td width="10%" align="center"><i>'.$name.'</i></td>
				<td width="54%" style="background: #eeeeee;">'.$value.'</td>
				<td width="4%";>'.$author.'</td>
				<td width="18%">'.$time.'</td>
				<td width="2%">'.$flag.'</td>
				<td width="2%">'.$level.'</td>
				<td width="8%"><a href="">E</a>/<a href="">D</a></td>
				</tr>
				<tr><td colspan="9"><hr></td></tr>';
		}
	}
	print "</table>";
	print end_html;

}

sub show_com() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Command DB Editor');
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Kommando</b></td>
			<td align="center"><b>Dataname</b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b>Autor</b></td>
			<td align="center"><b>Datum</b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="9"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^com-'");
	if ( $sth->execute ) {
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			my $nr = $row[0];
			my $name = $row[1];
			my $value = $row[2];
			my $author = $row[3];
			my $time = $row[4];
			my $changed = $row[5];
			my $flag = $row[6];
			my $level = $row[7];
			my $command = "";
			if ($name =~ m/^com-(.*)/) { $command = $1; }; 
			print '<tr>
				<td width="2%">'.$nr.'</td>
				<td width="10%" align="center"><b>!'.$command.'</b></td>
				<td width="10%" align="center"><i>'.$name.'</i></td>
				<td width="54%" style="background: #eeeeee;"><code>'.$value.'</code></td>
				<td width="4%";>'.$author.'</td>
				<td width="18%">'.$time.'</td>
				<td width="2%">'.$flag.'</td>
				<td width="2%">'.$level.'</td>
				<td width="8%"><a href="">E</a>/<a href="">D</a></td>
				</tr>
				<tr><td colspan="9"><hr></td></tr>';
		}
	}
	print "</table>";
	print end_html;
}

sub dump_database() {
	print "DROP TABLE IF EXISTS `data`;

		CREATE TABLE `data` (
		`nr` int(10) unsigned NOT NULL AUTO_INCREMENT,
		`name` varchar(100) NOT NULL,
		`value` blob,
		`author` varchar(100) DEFAULT NULL,
		`time` varchar(100) DEFAULT NULL,
		`changed` tinyint(2) DEFAULT NULL,
		`flag` char(2) NOT NULL DEFAULT 'rw',
		`level` tinyint(2) DEFAULT NULL,
		PRIMARY KEY (`nr`)
		);

		LOCK TABLES `data` WRITE;
		/*!40000 ALTER TABLE `data` DISABLE KEYS */;";
	my $sth = $dbh->prepare("SELECT * FROM data");
	if ( $sth->execute ) {
	    while( my @row = $sth->fetchrow_array() ) {
			my $name = $row[0];
			my $value = $row[1];
			$value =~ s/\'//g;
			#$value =~ s/\"/\\\"/g;
			my $author = $row[2];
			if (!defined $row[3]) { $row[3] = ""; };
			my $time = $row[3];
			if (!defined $row[4]) { $row[4] = ""; };
			my $changed = $row[4];
			my $flag = $row[5];
			my $level = $row[6];
			#INSERT INTO Customers (CustomerName, ContactName, Address, City, PostalCode, Country)
			# VALUES ('Cardinal','Tom B. Erichsen','Skagen 21','Stavanger','4006','Norway');
			print("INSERT INTO data (name, value, author, time, changed, flag, level) VALUES ('".$name."','".$value."','".$author."','".$time."','".$changed."','".$flag."','".$level."');\n");
	    }
	}
	print "/*!40000 ALTER TABLE `data` ENABLE KEYS */;
			UNLOCK TABLES;"
}


$_ = param('a');

CASE: {
     /^calc/i and do { show_calc(); last CASE; };
     /^data/i and do { show_data(); last CASE; };
     /^var/i and do { show_var(); last CASE; };
     /^nvar/i and do { show_nvar(); last CASE; };
     /^com/i and do  { show_com(); last CASE; };
     /^dump/i and do { dump_database(); last CASE; };
     # default
     show_calc();
}

$dbh->disconnect;

