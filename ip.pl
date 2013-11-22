#!/usr/bin/perl -w
# $Id$
use strict;
$|++;

use CGI;

my $cgi = CGI->new;

print $cgi->header;
print $cgi->start_html;
print $cgi->pre( $ENV{'REMOTE_ADDR'} );
print $cgi->end_html;
