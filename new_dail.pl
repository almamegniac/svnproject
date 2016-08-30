#!/usr/bin/perl

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate);
use DBI();

$timestamp = scalar localtime(time());
$mo = (localtime)[4] + 1;
$da = (localtime)[3];
$yr = (localtime)[5] + 2000 - 100;

$debug = 0;

#Generic URL Constructor for Yahoo! Finance
$URLA="http://chart.yahoo.com/table.csv?s=";
$URLB="&a=". $mo . "&b=" . $da . "&c=" . $yr . "&d=" . 
       $mo . "&e=" . $da . "&f=" . $yr . "&g=d&q=q&y=0&x=.csv";

$logfile = "./log/d$yr$mo$da";


#### Application Initializations
# Connect to the database
my $a=new ramjack();


# Open status file for writing
open SF, "+>logfile_daily" or die "Can't open/create logfile: $!";
autoflush SF;
print SF $timestamp . ": Daily Update Initiated. \n";

# Grab list of symbols from market database
my $sth = $a->{"dbh"}->prepare("select idx, symbol from market");

$sth->execute();

print SF $timestamp . ": Daily Update initial query finished. \n";

while ( my $ref = $sth->fetchrow_hashref() ) {
   $URL = $URLA . $ref->{symbol} . $URLB;

   if ( $debug ) {
      print "Starting [" . $ref->{idx} . "]\n";
      print "Executing URL for: " . $ref->{symbol} . "\n";
   }

   #### See if data exists already for this symbol on this day.
   if ( ! $a->test_MarketDate("SYMBOL"	=> $ref->{symbol},
			"DSTAMP"	=> "$yr-$mo-$da") )
      {


      ##### Grab URL from location specified above
      $content = get($URL);
      @lines = split /\n/, $content;

      if ( $#lines eq 0 ) {
         print SF $timestamp . ": Daily Update ERROR: no close data found for ".
   			$ref->{symbol} . ". \n";
      }

      else {
         print "Processing lines: " . $ref->{symbol} . "\n";

         $i=1;
         my(@DatHash);
         while ( $lines[$i] ) {

            $dat = {};
            @lin = split /,/, $lines[$i];

            $date = ParseDate($lin[0]);
            $dte = UnixDate($date, "%Y-%m-%d");

            $dat->{Date} = $dte;
            $dat->{Open} = $lin[1];
            $dat->{Hi} = $lin[2];
            $dat->{Lo} = $lin[3];
            $dat->{Close} = $lin[4];
            $dat->{Vol} = $lin[5];

            push @DatHash, $dat;
            $i=$i+1;
            }

         print "Putting " . $ref->{symbol} . " into the database\n";

         for ( $i = $#DatHash ; $i ge 0 ; $i-=1 ) {
            eval { $a->{"insert_daily"}$dbh->do("INSERT INTO daily 
   	   	( market_idx, open, hi, lo, close, vol, dstamp )
   	   	VALUES
	   	( ".$ref->{idx}.",".$DatHash[$i]{Open}.",".$DatHash[$i]{Hi}.",
		".$DatHash[$i]{Lo}.",".$DatHash[$i]{Close}.",
		".$DatHash[$i]{Vol}.",'".$DatHash[$i]{Date}."');")};


            print SF $timestamp . ": Daily Update ERROR inserting record: $@. \n" if $@;
            print "Record Insert failed: $@\n" if $@;
            }
         }
      }
   }

$sth->finish();
$dbh->disconnect();
exit(0);

