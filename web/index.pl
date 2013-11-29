#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);

print header;
print start_html('ninbot Calc Database Editors')."\n";
print h1("ninbot Calc Database Editors")."\n";
print "<a href='showcalc.pl?a=calc'>Calc Editor</a>".br();
print "<a href='showcalc.pl?a=com'>Command Editor</a>".br();
print "<a href='showcalc.pl?a=var'>Variables Editor</a>".br();
print "<a href='showcalc.pl?a=nvar'>Nick Variables Editor</a>".br();
print "<a href='showcalc.pl?a=data'>Data Calc Editor</a>".br();

print end_html;
