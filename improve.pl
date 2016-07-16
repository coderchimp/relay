#!/usr/bin/perl

local $/ = "\r";

$improved = 0;
$baseline = 0;
$count = 0;
while (<>)
{
  if (/^\"(\D.*)\s+\((\d+)\)\s*([BG])/)
  {
    if ($baseline != 0)
    {
      while ($count != 5)
      {
        print "\t";
        $count++;
      }
      $percent = ($baseline-$improved)/$baseline;
      print $percent;
    }
    $count = 0;
    $baseline = 0;
    $improved = 0;
    print "\n$1\t$3\t$2\t";
    if ($2 <= 6) {print "6\t";}
    elsif ($2 <= 8) {print "8\t";}
    elsif ($2 <= 10) {print "10\t";}
    elsif ($2 <= 12) {print "12\t";}
    elsif ($2 <= 14) {print "14\t";}
    else {print "18\t";}
  }
  elsif (!/Baseline/)
  {
    @values = split /,/;
    $count++;
    $value = $values[0];
    chop($value);
    if ($value =~ /(\d)\:(.*)/)
    {
      $value = $1*60 + $2;
    }
    $improved += $value;
    #print "i=$improved v=$value ";
    print "$values[2]\t";
    #print "$values[3]\t";
  #  if (/^[\d.:S]+\s+\w\s*(-{0,1}\d{0,1}\:{0,1}\d+\.\d+)\s/)
  #  {
  #    print "$1\t";
  #  }
  #  else
  #  {
  #    print "\n";
  #    print;
  #    print "\n";
  #  }
  }
  else
  {
    @values = split /,/;
    $value = $values[0];
    chop($value);
    if ($value =~ /(\d)\:(.*)/)
    {
      $value = $1*60 + $2;
    }
    $baseline += $value;
    #print "b=$baseline v=$value ";
  }
}

    if ($baseline != 0)
    {
      while ($count != 5)
      {
        print "\t";
        $count++;
      }
      $percent = ($baseline-$improved)/$baseline;
      print $percent;
    }

print "\n";

