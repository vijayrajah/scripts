#!/bin/bash



CUR=$(date '+%s')
PAST=$((CUR-3600))

perl -e '@abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($ARGV[0]); 
$year += 1900; 
$mon1 =$abbr[$mon];
$mon++;
print "$year$mon$mday$hour$min$sec";' $PAST
