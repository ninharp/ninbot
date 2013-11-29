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
	print h1('ninbot Calc DB Editor');
	print "<TABLE width='100%' BORDER='1'>\n\t<TR><TD width='5%'>Nr.</TD><TD width='20%'>Name</TD><TD WIDTH='65%'>Inhalt</TD><TD WIDTH='10%'>Author</TD></TR>\n";
	my $sth = $dbh->prepare("SELECT * FROM calc WHERE name NOT REGEXP '(^data-)|(^com-)'");
	if ( $sth->execute ) {
		my $counter = 1;
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			print "\t<TR><TD>".$counter."</TD><TD>".$row[0]."</TD><TD>".$row[1]."</TD><TD>".$row[2]."</TD></TR>\n";
			$counter++;
		}
	}
	$sth->finish();
	print "</TABLE>";
}

sub show_data() {
	print h1('ninbot Data Variable DB Editor');
	print "<TABLE width='100%' BORDER='1'>\n\t<TR><TD width='5%'>Nr.</TD><TD width='20%'>Name</TD><TD WIDTH='65%'>Inhalt</TD><TD WIDTH='10%'>Author</TD></TR>\n";
	my $sth = $dbh->prepare("SELECT * FROM calc WHERE name REGEXP '^data-'");
	if ( $sth->execute ) {
		my $counter = 1;
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			if ($row[0] !~ m/^data-.?var/i) {
				print "\t<TR><TD>".$counter."</TD><TD>".$row[0]."</TD><TD>".$row[1]."</TD><TD>".$row[2]."</TD></TR>\n";
				$counter++;
			}
		}
	}
	print "</TABLE>";
}

sub show_nvar() {
	print h1('ninbot Data Variable DB Editor');
	print "<TABLE width='100%' BORDER='1'>\n\t<TR><TD width='5%'>Nr.</TD><TD width='20%'>Name</TD><TD WIDTH='65%'>Inhalt</TD><TD WIDTH='10%'>Author</TD></TR>\n";
	my $sth = $dbh->prepare("SELECT * FROM calc WHERE name REGEXP '^data-nvar-'");
	if ( $sth->execute ) {
		my $counter = 1;
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			print "\t<TR><TD>".$counter."</TD><TD>".$row[0]."</TD><TD>".$row[1]."</TD><TD>".$row[2]."</TD></TR>\n";
			$counter++;
		}
	}
	print "</TABLE>";
}

sub show_var() {
	print h1('ninbot Data Variable DB Editor');
	print "<TABLE width='100%' BORDER='1'>\n\t<TR><TD width='5%'>Nr.</TD><TD width='20%'>Name</TD><TD WIDTH='65%'>Inhalt</TD><TD WIDTH='10%'>Author</TD></TR>\n";
	my $sth = $dbh->prepare("SELECT * FROM calc WHERE name REGEXP '^data-var-'");
	if ( $sth->execute ) {
		my $counter = 1;
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			if ($row[1] =~ m/@@/i) {
				print "\t<TR><TD>".$counter."</TD><TD>".$row[0]."</TD><TD>";
				print "<select size='3'>\n";
				my @arr = split(/@@/, $row[1]);
				foreach my $entry (@arr) {
					print "\t<option>".$entry."</option>\n";
				}
				print "</select>\n";
				print "</TD><TD>".$row[2]."</TD></TR>\n";
			} else {
				print "\t<TR><TD>".$counter."</TD><TD>".$row[0]."</TD><TD>".$row[1]."</TD><TD>".$row[2]."</TD></TR>\n";
			}
			$counter++;
		}
	}
	print "</TABLE>";
}

sub show_com() {
	print h1('ninbot Command DB Editor');
	print "<TABLE width='100%' BORDER='1'>\n\t<TR><TD width='5%'>Nr.</TD><TD width='20%'>Name</TD><TD WIDTH='65%'>Inhalt</TD><TD WIDTH='10%'>Author</TD></TR>\n";
	my $sth = $dbh->prepare("SELECT * FROM calc WHERE name REGEXP '^com-'");
	if ( $sth->execute ) {
		my $counter = 1;
		while ( my @row = $sth->fetchrow_array() ) {
			if ( !defined $row[3] ) { $row[3] = ""; }
			if ( !defined $row[4] ) { $row[4] = ""; }
			if ( !defined $row[5] ) { $row[5] = ""; }
			print "\t<TR><TD>".$counter."</TD><TD>".$row[0]."</TD><TD>".$row[1]."</TD><TD>".$row[2]."</TD></TR>\n";
			$counter++;
		}
	}
	print "</TABLE>";
}

print header;
print start_html('ninbot Calc Database Editor')."\n";

$_ = param('a');

CASE: {
     /^calc/i and do { show_calc(); last CASE; };
     /^data/i and do { show_data(); last CASE; };
     /^var/i and do { show_var(); last CASE; };
     /^nvar/i and do { show_nvar(); last CASE; };
     /^com/i and do  { show_com(); last CASE; };
     # default
     show_calc();
     #generate_form();
}

$dbh->disconnect;

print end_html;
