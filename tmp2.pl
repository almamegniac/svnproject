#!/usr/bin/perl

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate);
use DBI();

$URLA="http://chart.yahoo.com/table.csv?s=";
$URLB="&a=10&b=13&c=2000&d=10&e=13&f=2000&g=d&q=q&y=0&x=.csv";

# Connect to the database.
my $dbh = DBI->connect("DBI:mysql:database=mkt1;host=localhost",
                        "root", "cambria",
                         {'RaiseError' => 1});

my $sth = $dbh->prepare("select idx, symbol from market");

$sth->execute();

$good = 0;
$bad = 0;

while ( my $ref = $sth->fetchrow_hashref() ) {

   if ( $ref->{symbol} !~ /\W/ ) {
	$good = $good +1;
   }
   else {
	$bad = $bad +1;

	eval { $dbh->do("delete from market where symbol = '" .
                        $ref->{symbol} . "';") };
	print "Record delete failed $@\n" if $@;

   }

}


print "Good:" . $good . "  " . $bad . "\n";
$sth->finish();
$dbh->disconnect();
exit(0);

