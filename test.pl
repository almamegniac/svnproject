#!/usr/bin/perl

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate);
use DBI();
use ramjack;

$status = "/Users/mgalgano/dev/perl/daily_status";
$timestamp = scalar localtime(time());
$mo = (localtime)[4] + 1;
$da = (localtime)[3];
$yr = (localtime)[5] + 2000 - 100;

my $a=new ramjack();

my $list = $a->get_Market_Range( 	"SYMBOL"	=> "orcl",
			"RGE"		=> ">=",
			"DSTAMP"	=> "2000-10-25",
			"SIZE"		=> "50" );

print "We have: " . $#{$list} . " X " . $#{$list->[0]} . ".\n";

for ($i = 0;$i<=$#{$list}; $i+=1 )
{
	for ($j=0;$j<=$#{$list->[$i]}; $j+=1 ) 
	{
		print "$list->[$i][$j] ";
	}
	print "\n";
}

exit(0);



print $a->test_Market(	"SYMBOL" => "GE" ) . "\n";
print $a->test_MarketDate(	"SYMBOL" => "GE", 
				"DSTAMP" => "2000-10-19" ) . "\n";

exit(0);

my $list = $a->get_Market_Data(	"SYMBOL" => "ORCL",
				"START" => "2000-09-01",
				"END" => "2000-10-18" );

print "We have: " . $#{$list} . " X " . $#{$list->[0]} . ".\n";

for ($i = 0;$i<=$#{$list}; $i+=1 )
{
	for ($j=0;$j<=$#{$list->[$i]}; $j+=1 ) 
	{
		print "$list->[$i][$j] ";
	}
	print "\n";
}


