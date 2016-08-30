#!/usr/bin/perl

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate);
use DBI();
use ramjack();
use yahoo;

$timestamp = scalar localtime(time());
$mo = (localtime)[4] + 1;
$da = (localtime)[3];
$yr = (localtime)[5] + 2000 - 100;

$debug = 0;

$logfile = "./log/s$yr$mo$da";


#### Application Initializations
# Connect to the database
my $a=new ramjack();
my $y=new yahoo();


# Open status file for writing
open SF, "+>$logfile" or die "Can't open/create logfile: $!";
autoflush SF;
print SF $timestamp . ": Daily Split Capture Started. \n";

@spts = $y->grab_splits("MONTH" => "11",
                        "YEAR"  => "00");

for ( $i = 0;$i<=$#spts; $i = $i + 1 ) {
   print "$i. $spts[$i]->{DATE}\n";

   if( $a->test_Split("SYMBOL" => $spts[$i]->{SYMBOL},
                  "EFFDATE" => $spts[$i]->{DATE} ) eq "0" ) {
	print "Insertting...\n";
      $a->insert_Split("SYMBOL" => $spts[$i]->{SYMBOL},
                       "EFFDATE" => $spts[$i]->{DATE},
                       "FACTOR"  => $spts[$i]->{SPLIT},
                       "DONE"    => 0 );
      }
   }

   




exit(0);

