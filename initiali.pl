#!/usr/bin/perl

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate);
use DBI();

$URLA="http://chart.yahoo.com/table.csv?s=";
$URLB="&a=10&b=13&c=2000&d=10&e=13&f=2000&g=d&q=q&y=0&x=.csv";
$input = "orcl";
$SYM = "ORCL";
$IDX = 2109;

# Connect to the database.
my $dbh = DBI->connect("DBI:mysql:database=mkt1;host=localhost",
                        "root", "cambria",
                         {'RaiseError' => 1});

my $sth = $dbh->prepare("select idx, symbol from market");

$sth->execute();

while ( my $ref = $sth->fetchrow_hashref() ) {
   $URL = $URLA . $ref->{symbol} . $URLB;

   print "Starting [" . $ref->{idx} . "]\n";
   print "Executing URL for: " . $ref->{symbol} . "\n";

   $content = get($URL);
   @lines = split /\n/, $content;


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
      eval { $dbh->do("INSERT INTO daily 
		( market_idx, open, hi, lo, close, vol, dstamp )
		VALUES
		( ".$ref->{idx}.",".$DatHash[$i]{Open}.",".$DatHash[$i]{Hi}.",
		".$DatHash[$i]{Lo}.",".$DatHash[$i]{Close}.",
		".$DatHash[$i]{Vol}.",'".$DatHash[$i]{Date}."');")};


      print "Record Insert failed: $@\n" if $@;
      }
   }

$sth->finish();
$dbh->disconnect();
exit(0);

