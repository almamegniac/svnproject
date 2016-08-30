package ramjack;

use LWP::Simple;
use Date::Manip qw(ParseDate UnixDate DateCalc);
use DBI;
use Carp;


sub new()
{
	my $that = shift;
	my $class = ref($that) || $that;
	my $self = {
		"debug"		=> 0,
		"dbh"		=> undef
	};

	bless $self, $class;

	my (@conStr) = qw( DBI:mysql:database=mkt1;host=localhost splunge cambria );
	carp "Unable to access mkt1: $DBI::errstr" 
		if (! ($self->{"dbh"} = DBI->connect(@conStr)));

	$self->initialize;
	return $self;
}

sub initialize
{
	my $self = shift;

        $self->{"exist_Market"} =
                $self->{"dbh"}->prepare("select idx from market where symbol = ?")
                        or die "exist_Market: prepare error:  $DBI::errstr\n";

        $self->{"exist_MarketDate"} =
                $self->{"dbh"}->prepare("select count(a.idx) from daily a, 
                        market b where a.market_idx = b.idx and b.symbol = ?
                        and a.dstamp = ?") 
                 or die "exist_MarketDate: prepare error:  $DBI::errstr\n";

	$self->{"exist_Split"} = 
		$self->{"dbh"}->prepare("select count(idx) from split 
			where midx = ? and effdate = ?")
                 or die "exist_Split: prepare error:  $DBI::errstr\n";

	$self->{"insert_Split"} = 
		$self->{"dbh"}->prepare("INSERT INTO split
		( midx, effdate, factor, done )
		values ( ?,?,?,? )")
		or die "insert_Split: prepare error: $DBI::errstr\n";

	$self->{"update_Split"} =
		$self->{"dbh"}->prepare("UPDATE split SET
		done = ? WHERE midx = ? and effdate = ?")
		or die "update_Split: prepare error: $DBI::errstr\n";

        $self->{"select_all_markets"} =
                $self->{"dbh"}->prepare("select symbol from market order by symbol asc")
                        or die "select_all_markets: prepare error:  $DBI::errstr\n";

         $self->{"insert_daily"} = 
		$self->{"dbh"}->prepare("INSERT INTO daily 
   		( market_idx, open, hi, lo, close, vol, dstamp )
   		VALUES (?,?,?,?,?,?,?)")
		or die "insert_daily: prepare error: $DBI::errstr\n";


	$self->{"select_daily"} =
		$self->{"dbh"}->prepare("SELECT b.dstamp, a.symbol, b.open, b.hi, b.lo, b.close, b.vol
					FROM market a, daily b 	WHERE a.idx = b.market_idx 
					AND a.symbol = ? AND b.dstamp >= ? AND b.dstamp <= ?
					ORDER BY b.dstamp ASC")
		or die "select_daily: prepare error: $DBI::errstr\n";

	$self->{"update_daily"} =
		$self->{"dbh"}->prepare("UPDATE daily SET
		open = ?, hi = ?, lo = ?, close = ? WHERE midx = ? 
		and dstamp = ?")
		or die "update_daily: prepare error: $DBI::errstr\n";


}

sub DESTROY
{
    my $self = shift;
    $self->{"dbh"}->disconnect;
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


sub test_Market
{
	$self = shift;

	my $symbol 	= $self->getval("SYMBOL",	@_, "DIE"=>1);

	$self->{"exist_Market"}->execute($symbol)
		or die "exist_Market: execute error: DBI::errstr\n";

	my $result = $self->{"exist_Market"}->fetchrow;

	if ( $result eq "" ) {
		return '0';
	}
	else {
		return $result;
	}
	$self->{"exist_Market"}->finish;
}


sub test_MarketDate
{
	$self = shift;

	my $symbol 	= $self->getval("SYMBOL",	@_, "DIE"=>1);
	my $dstamp 	= $self->getval("DSTAMP",	@_, "DIE"=>1);

	$self->{"exist_MarketDate"}->execute($symbol,$dstamp)
		or die "exist_MarketDate: execute error: DBI::errstr\n";

	my $result = $self->{"exist_MarketDate"}->fetchrow;

	return $result;
}


sub get_Market_List
{
	$self = shift;

	$self->{"select_all_markets"}->execute()
		or die "select_all_markets: execute error: DBI:errstr\n";

	$list = $self->{"select_all_markets"}->fetchall_arrayref;

	return $list;
}


sub get_Market_Data
{
	$self = shift;

	my $symbol 	= $self->getval("SYMBOL",	@_, "DIE"=>1);
	my $sdate 	= $self->getval("START",	@_, "DIE"=>1);
	my $edate 	= $self->getval("END",		@_, "DIE"=>1);

	$self->{"select_daily"}->execute($symbol, $sdate, $edate);

	$list = $self->{"select_daily"}->fetchall_arrayref;

	return $list;
}


sub get_Market_Range
{
	$self = shift;

	my $symbol	= $self->getval("SYMBOL",	@_, "DIE"=>1);
	my $rge		= $self->getval("RGE",		@_, "DIE"=>1);
	my $dstamp	= $self->getval("DSTAMP", 	@_, "DIE"=>1);
	my $size	= $self->getval("SIZE", 	@_, "DIE"=>1);

	$dte = ParseDate($dstamp);
	$sz = $size + int($size/10) + 5;


	if ($rge eq ">") {
		$sdte = DateCalc($dte,"+ 1 business day");
		$edte = DateCalc($sdte, "+ $sz business days");
		}

	elsif ($rge eq "<") {
		$edte = DateCalc($dte,"- 1 business day");
		$sdte = DateCalc($edte, "- $sz business days");
		}

	elsif ($rge eq "<=" or $rge eq "=<") {
		$edte = $dte;
		$sdte = DateCalc($edte, "- $sz business days");
		}
		

	elsif ($rge eq ">=" or $rge eq "=>") {
		$sdte = $dte;
		$edte = DateCalc($sdte, "+ $sz business days");
		}

	else {
		print "ERROR: Illegal operator $rge.\n"
		}
		

	$self->{"select_daily"}->execute($symbol, 
 			UnixDate($sdte, "%Y-%m-%d"),
			UnixDate($edte, "%Y-%m-%d"));

	$list = $self->{"select_daily"}->fetchall_arrayref;

	$len = $#{$list};

	if ( $len > $size-1 ) {
		
		if ( $rge eq ">" or $rge eq ">=" or $rge eq "=>" ) {
			for ( $i=0;$i<=($size-1);$i=$i+1 ) {
				push @{$list2}, shift @{$list};
				}
			return $list2;
			}
		else {
			for ( $i=0;$i<=($len-$size);$i=$i+1 ) {
				shift @{$list};
				}
			}
		}

	$self->{"select_daily"}->finish;
	return $list;

}


sub insert_Daily_Price
{
	$self = shift;

	my $symbol	= $self->getval("SYMBOL",	@_, "DIE"=>1);
	my $open	= $self->getval("OPEN",		@_, "DIE"=>1);
	my $hi		= $self->getval("HI",		@_, "DIE"=>1);
	my $lo		= $self->getval("LO",		@_, "DIE"=>1);
	my $close	= $self->getval("CLOSE",	@_, "DIE"=>1);
	my $vol		= $self->getval("VOL",		@_, "DIE"=>1);
	my $dstamp	= $self->getval("DSTAMP",	@_, "DIE"=>1);

	$midx = $self->test_Market( "SYMBOL" 	=> $symbol );

	if ( $midx = '0' ) {
		return(0);
	}

	$self->{"insert_daily"}->execute($midx,$open,$hi,$lo,$close,$vol,$dstamp);
	$self->{"insert_daily"}->finish;

	return(1);

}

sub test_Split
{
	$self = shift;

	my $symbol	= $self->getval("SYMBOL",	@_, "DIE"=>1);
	my $effdate	= $self->getval("EFFDATE",	@_, "DIE"=>1);

	$midx = $self->test_Market( "SYMBOL" 	=> $symbol );

	if ( $midx == 0 ) {
		return(-1);
	}

	$self->{"exist_Split"}->execute($midx, $effdate);

	my $result = $self->{"exist_Split"}->fetchrow;
	$self->{"exist_Split"}->finish;

       print "Result: $result\n";

	if ( $result eq "" ) {
		return '0';
	}
	else {
		return $result;
	}


}


sub insert_Split
{
	$self = shift;

	my $symbol	= $self->getval("SYMBOL", 	@_, "DIE"=>1);
	my $effdate	= $self->getval("EFFDATE", 	@_, "DIE"=>1);
	my $factor	= $self->getval("FACTOR", 	@_, "DIE"=>1);
	my $done	= $self->getval("DONE", 	@_, "DIE"=>1);

	$midx = $self->test_Market( "SYMBOL" 	=> $symbol );

	$self->{"insert_Split"}->execute($midx,$effdate,$factor,$done);
	my $result = $self->{"insert_Split"}->finish;

	return(1);
}

1;
