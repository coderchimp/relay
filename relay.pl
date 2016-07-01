#!/usr/bin/perl

use Text::CSV;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                 or die "Cannot use CSV: ".Text::CSV->error_diag ();


# This script assumes there is a ODSL_toptimes.csv file in the current dir
# ODSL_toptimes.csv is a (a save as csv dump of the excel top times report)
# The script takes as input the csv dump of the excel report of the file generated
# Event -> Committed Athletes -> check the all button -> Export All Committed
# How to run
# relay.pl meet_export.csv > relays.csv
# Open relays.csv in excel and save as an xls for the coaches

sub parse_csv {
  my $text = shift; ## data containing comma-separated values
  my @new = ();
  
  return $text =~ m/("[^"]+"|[^,]+)(?:,*)?/g;
 
  push(@new, $+) while $text =~ m{
    ## the first part groups the phrase inside the quotes
    "([^\"\\]*(?:\\.[^\"\\]*)*)",?
      | ([^,]+),?
      | ,
    }gx;
    push(@new, undef) if substr($text, -1,1) eq ',';
    return @new; ## list of values that were comma-spearated
}

#This uses some globals because I was to lazy to implement this correctly
#The events hash is a hash of arrays 
#Each hash has all the swimmers listed in order of time
#This function takes that hash and grabs the top 4 unused swimmers in each event
#It computes the lowest time of each 256 permutations of those top swimmers
#It is smart enough to not compute times when a swimmer is repeated
sub max_relay
{
  $besttime = 99999;
  $curfree = 0;
  $numfree = $#{$events->{"Free"}};
  $numback = $#{$events->{"Back"}};
  $numbreast = $#{$events->{"Breast"}};
  $numfly = $#{$events->{"Fly"}};

  for ($free=0; $free < 4; $curfree++)
  {
    $free++;
    while ($curfree <= $numfree &&
           ($freename = ${$events->{'Free'}}[$curfree]) &&
           $used{$freename} == 1)
    {
      $debugname = ${$events->{'Free'}}[$curfree];
      #print "free used = $debugname\n";
      $curfree++;
    }

    if ($curfree <= $numfree)
    {
      #print "curfree = $curfree $freename used = $used{$freename} $numfree\n";

      $freetime = $times{$freename}{'Free'};
      $curback = 0;
      for ($back=0; $back < 4; $curback++)
      {
        $back++;
        while ($curback <= $numback && 
               ($backname = ${$events->{'Back'}}[$curback]) &&
               $used{$backname} == 1)
        {
          $debugname = ${$events->{'Back'}}[$curback];
          #print "back used = $debugname\n";
          $curback++;
        }
        if ($curback <= $numback && $backname ne $freename)
        {
          $backtime = $times{$backname}{'Back'};
          #print "curback = $curback $backname \n";

          $curbreast = 0;
          for ($breast=0; $breast < 4; $curbreast++)
          {
            $breast++;
            while ($curbreast <= $numbreast &&
                   ($breastname = ${$events->{'Breast'}}[$curbreast]) && 
                   $used{$breastname} == 1)
            {
              $debugname = ${$events->{'Breast'}}[$curbreast];
              #print "breast used = $debugname\n";
              $curbreast++;
            }

            if ($curbreast <= $numbreast && $breastname ne $freename && $breastname ne $backname)
            {
              $breasttime = $times{$breastname}{'Breast'};
              #print "curbreast = $curbreast $breastname \n";
              $curfly = 0;
              for ($fly=0; $fly < 4; $curfly++)
              {
                $fly++;
                while ($curfly <= $numfly && 
                       ($flyname = ${$events->{'Fly'}}[$curfly]) && 
                       $used{$flyname} == 1)
                {
                  $debugname = ${$events->{'Fly'}}[$curfly];
                  #print "fly used = $debugname\n";
                  $curfly++;
                }
                if ($curfly <= $numfly && $flyname ne $freename && $flyname ne $backname && $flyname ne $breastname)
                {
                  $flytime = $times{$flyname}{'Fly'};
                  #print "curfly = $curfly $flyname \n";
                  $totaltime = ($freetime/$factor) + ($backtime/$factor) + ($flytime/$flyfactor) + ($breasttime/$factor);
                  if ($totaltime < $besttime)
                  {
                    $besttime = $totaltime;
                    @bestgroup = ($backname, $breastname, $flyname, $freename);
                  }
                  else
                  {
                    #print "$totaltime is not better than $besttime\n";
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  #print "besttime = $besttime\n";
  return ($besttime < 9999);
}

open my $fh, "<:encoding(utf8)", $ARGV[0] or die "$ARGV[0]: $!";
my $header = $csv->getline( $fh );
while ( my $row = $csv->getline( $fh ) )
{
  @record = @{$row};
  #my $counter = 0;
  #foreach $item (@record)
  #{
  #  print "$counter !$item!\n";
  #  $counter++;
  #}
  #print "\n";
  my $use = 1; # default to 1 at coach request
  if ($record[0] =~ /\w+/)
  {
    if ($record[6] =~ /relay/i || $record[6] =~ /no/i || $record[6] =~ /yes/i )
    {
      #print STDERR "-- $line --\n$record[6]\n";
      if (!($record[6] =~ /yes\s+relay/i))
      {
        if ($record[6] =~ /no/i || $record[6] =~ /un/i)
        {
          if ($record[6] =~ /relay/i)
          {
            print "\"$record[0]\"\t$record[6]\n";
            $use = 0;
          }
          else
          {
            print STDERR "Negitive but unknown parse \"$record[0]\"\t$record[6]\n";
            $use = 1;
          }
        }
        elsif (!($record[6] =~ /yes/i ||
                 $record[6] =~ /please/i ||
                 $record[6] =~ /like/i || 
                 $record[6] =~ /want/i || 
                 $record[6] =~ /love/i ||
                 $record[6] =~ /will/i ||
                 $record[6] =~ /can/i ||
                 $record[6] =~ /^\s*relays*\s*$/i))
        {
          print STDERR "$record[0] has unknown relay statement $record[6]\n";
          $use = 1;
        }
        else
        {
          #print STDERR "$record[0] - treat as yes to relay $record[6]\n";
        }
      }
    }
    elsif (!($record[6] =~ /^\s*$/i))
    {
      #print STDERR "\nComments but no relay - $record[0] - $record[6]\n";
      $use = 1;
    }
    else
    {
      #print STDERR "-- $line\n";
      $use = 1;
    }
  }
  if ($use == 1)
  {
    $swimmers{$record[0]} = 1;
    $usedswimmers{$record[0]} = 0;
  }
}
$csv->eof or $csv->error_diag();
close $fh;

# at this point $swimmers is a has with all the names of kids doing relays
# the $used hash is initialized to everybody not used

$sex;
$agegroup;
$event;
$length;
print "\n";
open my $fh, "<:encoding(utf8)", "ODSL_toptimes.csv" or die "ODSL_toptimes.csv: $!";
my $header = $csv->getline( $fh );
while ( my $row = $csv->getline( $fh ) )
{
  if ($row->[0] =~ /^\w/)
  {
    if ($row->[0] =~ /(^Female[^\,]+)/ || $row->[0] =~ /(^Male[^\,]+)/)
    {
      $category = $1;
      if ($category =~ /(\w*ale)\s+(.*)\s+(\d\d\d*)\s(\w+)/)
      {
        $sex = $1;
        $agegroup = $2;
        $length = $3; 
        $event = $4;
        #print "sex = $sex age = $agegroup length = $length event = $event\n";
      }
      else
      {
        print "------------------------------- $category\n";
      }
    }
    else
    { 
      $name = $row->[3];
      $name =~ s/\s*$//;
      #print "name = !$name!\n";

      #print "time = !$row->[1]!\n";
      #!1:25.36S!
      #!40.71S!
      if($row->[1] =~ /(\d+):(\d+)\.(\d+)/)
      {
        #print "minute ";
        $time = ($1*60) + $2 + ($3/100);
      }
      else
      {
        #print "sec ";
        $row->[1] =~ /(\d+)\.(\d+)/;
        $time = $1 + ($2/100);
      }
      #print "converted = $time\n";
      $times{$name}{$event} = $time;
      push (@{$grid->{$sex}{$agegroup}{$event} }, $name);
    }
  }
}

# at this point all the times for the swimmers have been loaded into a has called $times
# There is a giant hash array called grid that has the swimmers by sex, agegroup and event listed
# by time

#print "\n\n";

foreach $sex ("Female","Male")
{
  my @free = ();

  # For the 8&under just list them by free time since they dont do a medley
  foreach $name (@{$grid->{$sex}{"8 & Under"}{"Free"}})
  {
    if ($swimmers{$name} == 1)
    {
      push @free, $name;
      $usedswimmers{$name} = 1;
    }
  }
  print "$sex 8&under by Free time\n";
  print "Name,Time\n";
  foreach $name (@free)
  {
    print "\"$name\",$times{$name}{'Free'}\n";
  }
  print "Max Relay,second fastest,slowest,third fastest,fastest\n";
  $letter = "A";
  for ($count = 0; ($count+3) <= $#free; $count += 4)
  {
    print "$letter,\"$free[$count+1]\",\"$free[$count+3]\",\"$free[$count+2]\",\"$free[$count]\"\n";
    $used{$free[$count]} = 1;
    $used{$free[$count+1]} = 1;
    $used{$free[$count+2]} = 1;
    $used{$free[$count+3]} = 1;
    $letter++;
  }
  $headerflag = 1;
  for (;$count <= $#free; $count++)
  {
    if ($headerflag == 1)
    {
      print "Unused\n";
      $headerflag = 0;
    }
    print "\"$free[$count]\",";
  }
  print "\n\n";
  
  # for the 4 medleys we need to print the times for that age group
  # and then compute the max relays
  foreach $agegroup ("9-10", "11-12", "13-14", "15-18")
  {
    undef %used;
    foreach $event ("Free", "Back", "Breast", "Fly")
    {
      @{$events->{$event}} = ();
      foreach $name (@{$grid->{$sex}{$agegroup}{$event}})
      {
        if ($swimmers{$name} == 1)
        {
          push @{$events->{$event}}, $name;
          $used{$name} = 0;
          $usedswimmers{$name} = 1;
        }
      }
    }
    # The events hash has now been set up
 
    # show the times in the medley order to make it easier to see
    print "$agegroup Medley by Times\n";
    print "Back Name,Back Time,Breast Name,Breast Time,Fly Name,Fly Time,Free Name,Free Time\n";
    for ($count = 0; $count <= $#{$events->{"Free"}}; $count++) 
    {
      foreach $event ("Back", "Breast", "Fly", "Free")
      {
        if ($count <= $#{$events->{$event}})
        {
          $name = ${$events->{$event}}[$count];
          print "\"$name\",$times{$name}{$event},";
        }
        else
        {
          print ",,";
        }
      }
      print "\n";
    }

    # setup the global var called factor
    # this is used to decide if the times should be divided by
    # something based on age group

    $factor = 2;
    if ($agegroup eq "15-18")
    {
      $factor = 1;
    }
    $flyfactor = $factor;
    if ($agegroup eq "9-10")
    {
      $flyfactor = 1;
    }
    $printHeader = 1;
    foreach $relayLetter ("A", "B", "C", "D")
    {
      # call max_relay to compute the best relay of avail swimmers
      if (max_relay)
      {
        if ($printHeader == 1)
        {
          $printHeader = 0;
          if ($factor != 1)
          {
            if ($flyfactor == 1)
            {
              print "\"*Back, Breast and Free were divided by $factor to account for 50->25 conversion\"\n";
            }
            else
            {
              print "\"*Back, Breast, Fly and Free were divided by $factor to account for 50->25 conversion\"\n";
            }
          }
          print "Max Relay,Back,Breast,Fly,Free,Est Time\n";
        }
        # print the relay that was identified and set the swimmers to used
        print "$relayLetter,";
        foreach $name (@bestgroup)
        {
          print "\"$name\",";
          $used{$name} = 1;
        }
        print "$besttime\n";
      }
    }
    $usedcount = 0;
    foreach $name (sort keys %used)
    {
      if ($used{$name} == 0)
      {
        if ($usedcount == 0)
        {
          print "Unused\n";
        }
        else
        {
          if ($usedcount % 4 == 0)
          {
            print "\n";
          }
          else
          {
            print ",";
          }
        }
        $usedcount++;
        print "\"$name\"";
      }
    }
    print "\n\n";
  }
}

$notime=0;
foreach $name (keys %swimmers)
{
  if ($usedswimmers{$name} != 1)
  {
    if ($notime == 0)
    {
      print "Relay swimmers who have no times\n";
      $notime = 1;
    }
    print "\"$name\"\n";
  }
}
