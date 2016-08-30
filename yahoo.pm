package yahoo;
##################
#
# Yahoo! Market Data Resource Parser
#
# Market Data Parser
# Split Data Parser
#
##################

use LWP::Simple;
use HTML::Parser 3.00 ();
use Date::Manip qw(ParseDate UnixDate);
use DBI();


#######
# Yahoo! URL for the Split Data
#
# Append "yy/smm.html"
#
my $URL = "http://biz.yahoo.com/c/";
my $htfile = "";

my %inside;

open FH, $fname;


sub new()
{
        my $that = shift;
        my $class = ref($that) || $that;
        my $self = {
                "debug"         => 0,
        };

        bless $self, $class;

        return $self;
}

sub getval
{
        my $self  = shift;
        my $param = shift;

        my %vals = @_;

        if ($self->{"debug"})
        {
                print "---------------\n";
                print "sub: get_param\n";
                print Dumper ($param);
                print Dumper (%vals);
                print "---------------\n\n";
        }

        my $die;
        my $default;

        if ((exists ($vals{"DIE"})) and (defined ($vals{"DIE"})))
        {
                $die = $vals{"DIE"};
        } else {
                $die = 0;
        }

        if ((exists ($vals{"DEFAULT"})) and (defined ($vals{"DEFAULT"})))
        {
                $default = $vals{"DEFAULT"};
        } else {
                $default = undef;
        }

        if ((exists ($vals{$param})) and (defined ($vals{$param})))
        {
                if (ref ($vals{$param}) eq 'ARRAY')
                {
                        return @{$vals{$param}};
                } else {
                        #
                        # Now check if the values are valid
                        #

                        if ((exists ($vals{"VALID_VALS"})) and (defined ($vals{"VALID_VALS"})))
                        {
                                my @valid_list = @{$vals{"VALID_VALS"}};
                                my $isvalid = 0;
                                foreach (@valid_list)
                                {
                                        if ($vals{$param} eq $_)
                                        {
                                                $isvalid = 1;

                                        }
                                }

                                if (not $isvalid)
                                {
                                        print "$param => '", $vals{$param}, "' not valid!\n";
                                        print "Possible values:\n";
                                        foreach (@valid_list)
                                        {
                                                print "\t$_\n";
                                        }
                                        die 'DMDS::getval terminating';
                                }
                        }

                        return $vals{$param};
                }
        } elsif ($die) {
                die "$param not given!\n";
        } else {
                return $default;
        }
}



sub tag
{
   my($tag, $num) = @_;
   $inside{$tag} += $num;
   if ( $tag eq "tr" ) {
      $htfile = $htfile .  "\n";  # not for all tags
   }
   else {
#      print "";  # not for all tags
   }
}

sub text
{
    return if $inside{script} || $inside{style};
    $str = $_[0];
    $str =~ tr/\n/ /;
#    print "$str\t";
    if ( $str eq "Calendar" ) {
       $htfile = $htfile . "\nBEGIN\n";
       }
    elsif ( $str eq "*" ) {
       $htfile = $htfile . "\nEND\n";
       }
    else {
       $htfile = $htfile . "$str\t";
       }
}

sub grab_splits
{ 
   $self = shift;

    my $mo = $self->getval("MONTH", @_, "DIE"=>1);
    my $yr = $self->getval("YEAR",  @_, "DIE"=>1);

   my $URL1 = "$URL$yr/s$mo.html";
  
   print "$URL1\n";

HTML::Parser->new(api_version => 3,
                  handlers    => [start => [\&tag, "tagname, '+1'"],
                                  end   => [\&tag, "tagname, '-1'"],
                                  text  => [\&text, "dtext"],
                                 ],
                  marked_sections => 1,
        )->parse(get($URL1)) || die "Can't open file: $!\n";;

#print "$htfile";

@lines = split /\n/, $htfile;

if ( $#lines eq 0 ) {
   print "ERROR: No split data found at $URL1\n";
   return;
}

######
#
# Find "BEGIN" Statement
#
$i = 1;

while ( $lines[$i] ne "BEGIN"  and $i < $#lines ) { $i = $i + 1; }

if ( $i eq $#lines ) {
   print "ERROR: No BEGIN statement found!\n";
   return;
}

$i = $i + 1;

######
#
# Parse lines until END statement is reached
#
my $rec = {};
my $j = 0;
while ( $lines[$i] ne "END" and $i < $#lines ) {

   if ( $lines[$i] ne "" ) { 
      my ( $da1, $da2, $name, $sym, $op, $split, $ann, 
           $bl1, $bl2 ) = split /\t/, $lines[$i];

         # Process Date
	 my $date = ParseDate($da2);
         $ndate = UnixDate($date, "%Y-%m-%d");

         # Process Split Factor
         my ( $den, $num ) = split /-/, $split;
         my $sp = $num / $den;

         $splits[$j]{DATE}   = $ndate;
         $splits[$j]{SYMBOL} = $sym;
         $splits[$j]{SPLIT}  = $sp;

         $j = $j + 1;
      }

   $i = $i + 1;
   }

return(@splits);
}

1;
