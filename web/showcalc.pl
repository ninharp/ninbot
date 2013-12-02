#!/usr/bin/perl -w

use strict;
use DBI;
use CGI qw(:standard);
use POSIX;

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
	my $sort = "nr";
	$sort = param("sort") if defined param("sort");
	my $sort_type = "asc";
	$sort_type = param("type") if defined param("type");
	my $sort_old_type = "asc";
	$sort_old_type = "desc" if ($sort_type =~ /asc/i);
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b><a href="?a='.param('a').'&sort=name&type='.$sort_old_type.'">Dataname</a></b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=author&type='.$sort_old_type.'">Autor</a></b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=time&type='.$sort_old_type.'">Datum</a></b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="8"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name NOT REGEXP '(^data-)|(^com-)' ORDER BY $sort $sort_type");
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
				<td width="8%"><a href="?a='.param('a').'&m=e&id='.$nr.'">E</a>/<a href="?a='.param('a').'&m=d&id='.$nr.'">D</a></td>
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
	my $sort = "nr";
	$sort = param("sort") if defined param("sort");
	my $sort_type = "asc";
	$sort_type = param("type") if defined param("type");
	my $sort_old_type = "asc";
	$sort_old_type = "desc" if ($sort_type =~ /asc/i);
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b><a href="?a='.param('a').'&sort=name&type='.$sort_old_type.'">Dataname</a></b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=author&type='.$sort_old_type.'">Autor</a></b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=time&type='.$sort_old_type.'">Datum</a></b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="8"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^data-' ORDER BY $sort $sort_type");
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
				<td width="8%"><a href="?a='.param('a').'&m=e&id='.$nr.'">E</a>/<a href="?a='.param('a').'&m=d&id='.$nr.'">D</a></td>
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
	my $sort = "nr";
	$sort = param("sort") if defined param("sort");
	my $sort_type = "asc";
	$sort_type = param("type") if defined param("type");
	my $sort_old_type = "asc";
	$sort_old_type = "desc" if ($sort_type =~ /asc/i);
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Variablenname</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=name&type='.$sort_old_type.'">Dataname</a></b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=author&type='.$sort_old_type.'">Autor</a></b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=time&type='.$sort_old_type.'">Datum</a></b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="9"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^data-nvar-' ORDER BY $sort $sort_type");
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
				<td width="10%" align="center"><b>'.$vname.'</b></td>
				<td width="10%" align="center"><i>'.$name.'</i></td>
				<td width="54%" style="background: #eeeeee;">'.$value.'</td>
				<td width="4%";>'.$author.'</td>
				<td width="18%">'.$time.'</td>
				<td width="2%">'.$flag.'</td>
				<td width="2%">'.$level.'</td>
				<td width="8%"><a href="?a='.param('a').'&m=e&id='.$nr.'">E</a>/<a href="?a='.param('a').'&m=d&id='.$nr.'">D</a></td>
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
	my $sort = "nr";
	$sort = param("sort") if defined param("sort");
	my $sort_type = "asc";
	$sort_type = param("type") if defined param("type");
	my $sort_old_type = "asc";
	$sort_old_type = "desc" if ($sort_type =~ /asc/i);
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Variablenname</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=name&type='.$sort_old_type.'">Dataname</a></b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=author&type='.$sort_old_type.'">Autor</a></b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=time&type='.$sort_old_type.'">Datum</a></b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="9"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^data-var-' ORDER BY $sort $sort_type");
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
				<td width="8%"><a href="?a='.param('a').'&m=e&id='.$nr.'">E</a>/<a href="?a='.param('a').'&m=d&id='.$nr.'">D</a></td>
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
	my $sort = "nr";
	$sort = param("sort") if defined param("sort");
	my $sort_type = "asc";
	$sort_type = param("type") if defined param("type");
	my $sort_old_type = "asc";
	$sort_old_type = "desc" if ($sort_type =~ /asc/i);
	print '<table width="100%" align="center" border="0" cellspacing="0" cellpadding="10">
			<th>
			<td align="center"><b>Kommando</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=name&type='.$sort_old_type.'">Dataname</a></b></td>
			<td align="center"><b>Kommandoscript</b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=author&type='.$sort_old_type.'">Autor</a></b></td>
			<td align="center"><b><a href="?a='.param('a').'&sort=time&type='.$sort_old_type.'">Datum</a></b></td>
			<td align="center"><b>F</b></td>
			<td align="center"><b>L</b></td>
			<td align="center"><b>A</b></td>
			</th>
			<tr><td colspan="9"><hr></td></tr>';
	my $sth = $dbh->prepare("SELECT * FROM data WHERE name REGEXP '^com-' ORDER BY $sort $sort_type");
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
				<td width="8%"><a href="?a='.param('a').'&m=e&id='.$nr.'">E</a>/<a href="?a='.param('a').'&m=d&id='.$nr.'">D</a></td>
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
			my $name = $row[1];
			my $value = $row[2];
			$value =~ s/\'//g;
			#$value =~ s/\"/\\\"/g;
			my $author = $row[3];
			if (!defined $row[4]) { $row[4] = ""; };
			my $time = $row[4];
			if (!defined $row[5]) { $row[5] = ""; };
			my $changed = $row[5];
			my $flag = $row[6];
			my $level = $row[7];
			print("INSERT INTO data (name, value, author, time, changed, flag, level) VALUES ('".$name."','".$value."','".$author."','".$time."','".$changed."','".$flag."','".$level."');\n");
	    }
	}
	print "/*!40000 ALTER TABLE `data` ENABLE KEYS */;
			UNLOCK TABLES;\n";
}

sub edit_calc() {
	print header;
	print start_html('ninbot Calc Database Editor');
	print h1('ninbot Calc DB Editor');
	my $nr = 454;
	$nr = param("id") if defined param("id");
	my $a = "calc";
	$a = param('a') if defined param('a');
	my $sth = $dbh->prepare("SELECT * FROM data WHERE nr LIKE '$nr'");
	if ( $sth->execute ) {
		my @row = $sth->fetchrow_array();
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
			print '<form action="?" method="POST">';
			print '<input type="hidden" name="a" value="'.$a.'" />';
			print '<input type="hidden" name="m" value="s" />';
			print '<input type="hidden" name="id" value="'.$nr.'" />';
			print '<table border="1">';
			print '<tr><td>Name: <input type="text" name="name" maxlength="100" value="'.$name.'"/></td>';
			print '<td>Author: <input type="text" name="author" maxlength="100" value="'.$author.'"/></td></tr>';
			print '<tr><td colspan="2">Inhalt:<br /><textarea name="value" cols="80" rows="10">'.$value.'</textarea></td></tr>';
			print '<tr><td>Flags: <select name="flag" size="1">';
			if ($flag eq "rw") {
				print '<option value="rw" selected>rw</option>';
				print '<option value="ro">ro</option>';
			} elsif ($flag eq "ro") {
				print '<option value="ro" selected>ro</option>';
				print '<option value="rw">rw</option>';
			} else {
				print '<option value="rw" selected>rw</option>';
				print '<option value="ro">ro</option>';
			}
			print '</select></td>';
			print '<td>Level: <select name="level" size="1">';
			if ($level == 0) {
				print '<option value="0" selected>0</option>';
			} else {
				print '<option value="0">0</option>';
			}
			if ($level == 1) {
				print '<option value="1" selected>1</option>';
			} else {
				print '<option value="1">1</option>';
			}
			if ($level == 2) {
				print '<option value="2" selected>2</option>';
			} else {
				print '<option value="2">2</option>';
			}
			if ($level == 3) {
				print '<option value="3" selected>3</option>';
			} else {
				print '<option value="3">3</option>';
			}
			if ($level == 4) {
				print '<option value="4" selected>4</option>';
			} else {
				print '<option value="4">4</option>';
			}
			if ($level == 5) {
				print '<option value="5" selected>5</option>';
			} else {
				print '<option value="5">5</option>';
			}
			if ($level == 6) {
				print '<option value="6" selected>6</option>';
			} else {
				print '<option value="6">6</option>';
			}
			if ($level == 7) {
				print '<option value="7" selected>7</option>';
			} else {
				print '<option value="7">7</option>';
			}
			if ($level == 8) {
				print '<option value="8" selected>8</option>';
			} else {
				print '<option value="8">8</option>';
			}
			if ($level == 9) {
				print '<option value="9" selected>9</option>';
			} else {
				print '<option value="9">9</option>';
			}
			if ($level == 10) {
				print '<option value="10" selected>10</option>';
			} else {
				print '<option value="10">10</option>';
			}
			print '</select></td></tr>';
			print '<tr><td>&nbsp;</td><td align="right"><input type="submit" name="save" value="Save"/></td></tr>';
			print '</table></form>';
	}
	$sth->finish();
	print end_html;
}

sub ask_del_calc() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Command DB Editor');
	my $nr = 1;
	$nr = param('id') if defined param('id');
	my $a = "calc";
	$a = param('a') if defined param('a');
	print '<table border="1" width="100%" align="center">';
	print '<form action="?" method="">';
	print '<input type="hidden" name="a" value="'.$a.'" />';
	print '<input type="hidden" name="m" value="x" />';
	print '<input type="hidden" name="id" value="'.$nr.'" />';
	print '<tr><td align="center">You wanna really delete entry number '.$nr.'?</td></tr>';
	print '<tr><td align="center"><input type="submit" name="delete" value="Delete"/></td></tr>';
	print '</form></table>';
	print end_html;
}

sub del_calc() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Command DB Editor');
	my $nr = 1;
	my $a = "calc";
	$a = param('a') if defined param('a');
	$nr = param('id') if defined param('id');
	my $sth = $dbh->prepare("DELETE FROM data WHERE nr = '$nr'");
	my $ret = $sth->execute;
	print '<table border="1" width="100%" align="center">';
	if ($ret == 1) {
		print '<tr><td align="center">Successfully deleted entry number '.$nr.'!</td></tr>';
	} else {
		print '<tr><td align="center">An error occured on deleting number '.$nr.'!</td></tr>';
	}
	print '<tr><td align="center"><a href="?a='.$a.'">Back to list</a></td></tr>';
	print '</table>';
	print end_html;
}

sub save_calc() {
	print header;
	print start_html('ninbot Calc Database Editor')."\n";
	print h1('ninbot Command DB Editor');
	my $nr = 1;
	my $a = "calc";
	my $name = "";
	my $author = "";
	my $time = "";
	my $changed = "";
	my $flag = "rw";
	my $value = "";
	my $level = "0";
	my $time = strftime "%a %b %e %H:%M:%S %Y", localtime;
	$a = param('a') if defined param('a');
	$nr = param('id') if defined param('id');
	$name = param('name') if defined param('name');
	$author = param('author') if defined param('author');
	$flag = param('flag') if defined param('flag');
	$level = param('level') if defined param('level');
	$value = param('value') if defined param('value');
	print '<table border="1" width="100%" align="center">';
	if ($name ne "" and $value ne "") {
		my $sth = $dbh->prepare("UPDATE data SET name='$name',value='$value',author='$author',time='$time',changed='$changed',flag='$flag',level='$level' WHERE nr='$nr'");
		my $ret = $sth->execute;
		if ($ret == 1) {
			print '<tr><td align="center">Successfully edited entry number '.$nr.'!</td></tr>';
		} else {
			print '<tr><td align="center">An error occured on editing number '.$nr.'!</td></tr>';
		}
	}
	print '<tr><td align="center"><a href="?a='.$a.'">Back to list</a></td></tr>';
	print '</table>';
	print end_html;
}


if (!defined param('m')) {
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
} else {
	$_ = param('m');

	CASE: {
     /^e/i and do { edit_calc(); last CASE; };
     /^d/i and do { ask_del_calc(); last CASE; };
     /^x/i and do { del_calc(); last CASE; };
     /^s/i and do { save_calc(); last CASE; };
     # default
     show_calc();
	}
}

$dbh->disconnect;

