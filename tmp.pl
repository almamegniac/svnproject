#!/usr/bin/perl

use LWP::Simple;
use HTML::Parser 3.00 ();

my $fname = "./s10.html";

my %inside;

open FH, $fname;

sub tag
{
   my($tag, $num) = @_;
   $inside{$tag} += $num;
   if ( $tag eq "tr" ) {
      print "\n";  # not for all tags
   }
   else {
      print " ";  # not for all tags
   }
}

sub text
{
    return if $inside{script} || $inside{style};
    $str = $_[0];
    $str =~ tr/\n/ /;
    print "[$str]";
}

HTML::Parser->new(api_version => 3,
                  handlers    => [start => [\&tag, "tagname, '+1'"],
                                  end   => [\&tag, "tagname, '-1'"],
                                  text  => [\&text, "dtext"],
                                 ],
                  marked_sections => 1,
        )->parse_file($fname) || die "Can't open file: $!\n";;



