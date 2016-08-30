#!/usr/bin/perl

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate);
use DBI();

$status = "/galgano/devel/perl/daily_status";
$timestamp = scalar localtime(time());
$mo = 10;
$da = 13;
$yr = 2000;

#Generic URL Constructor for Yahoo! Finance
$URLA="http://chart.yahoo.com/table.csv?s=";
$URLB="&a=". $mo . "&b=" . $da . "&c=" . $yr . "&d=" . 
       $mo . "&e=" . $da . "&f=" . $yr . "&g=d&q=q&y=0&x=.csv";

#### Application Initializations
# Connect to the database.
my $dbh = DBI->connect("DBI:mysql:database=mkt1;host=localhost",
                        "root", "cambria",
                         {'RaiseError' => 1});

# Open status file for writing
open SF, "+>logfile_selective" or die "Can't open/create logfile: $!";
autoflush SF;
print SF $timestamp . ": Selective mo=". $mo ." da=" . $da . " Update Initiated. \n";

# Grab list of symbols from market database
my $sth = $dbh->prepare("select idx, symbol from market");

$sth->execute();

print SF $timestamp . ": Selective Update initial query finished. \n";

while ( my $ref = $sth->fetchrow_hashref() ) {

   my $sth2 = $dbh->prepare("select a.idx from market a, daily_equity b
                where a.idx = b.market_idx and b.dstamp = '" .
                $yr . "-" . $mo . "-" . $da . "' and a.symbol = '" .
                $ref->{symbol} . "';");
   eval { $sth2->execute() };
   print SF $timestamp . ": Selective Update ERROR testing record: $@. \n" if $@;
   print "Record Test failed: $@\n" if $@;
   my $table = $sth2->fetchall_arrayref()
		or die "$sth2->errstr\n";

   if ( $#{$table} lt 0 ) {
      print SF $timestamp . ": Selective Update found no data for " .
                $ref->{symbol} . " on " . $yr . $mo . $da . ".\n";

      $URL = $URLA . $ref->{symbol} . $URLB;

      print "Starting [" . $ref->{idx} . "]\n";
      print "Executing URL for: " . $ref->{symbol} . "\n";

      $content = get($URL);
      @lines = split /\n/, $content;

      if ( $#lines eq 0 ) {
         print SF $timestamp . ": Selective Update ERROR: no close data found for ".
   			$ref->{symbol} . " on " . $yr . $mo . $da . ". \n";
      }

      else {
         print "Processing lines: " . $ref->{symbol} . "\n";
         exit(0);

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
            eval { $dbh->do("INSERT INTO daily_equity 
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

