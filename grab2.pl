#!/usr/bin/perl

use LWP::Simple;

$URL="http://chart.yahoo.com/table.csv?s=orcl&a=1&b=1&c=1989&d=10&e=8&f=2000&g=d&q=q&y=0&z=orcl&x=.csv";
$input = "orcl";

open (FH, "< $input");
$content =  <FH>;
close(FH);
print "Got the URL...\n";

@lines = split /\n/, $content;
print "split up the content...\n";

$i=1;
while ( $lines[$i] ) {

   $dat = {};
   @lin = split /,/, $lines[$i];
   print $lin[0] . "\n";
   $dat->{Date} = $lin[0];
   $dat->{Open} = $lin[1];
   $dat->{Hi} = $lin[2];
   $dat->{Lo} = $lin[3];
   $dat->{Close} = $lin[4];
   $dat->{Vol} = $lin[5];

   push @DatHash, $dat;
   $i=$i+1;
   }

for ( $i=$#DatHash ;$i != 0; $i-=1 ) {
   print "[".$i."] " . $DatHash[$i]{Date} . "\n";
   }

$num_keys = scalar keys %dat;

print $num_keys . "\n";

