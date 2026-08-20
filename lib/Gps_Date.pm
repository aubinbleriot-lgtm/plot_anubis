#!/usr/bin/perl -w
# =================================================================
#
# Name    : Gps_Date
#
# Purpose : Convert and calculate Date and Time.
#
# Author  : J. Dousa
#
# Created : 20 Mar 2001
#
# Changes : 20-Apr-2004 mm: new option '-doy'
#           18-Oct-2004 ss: Additional output features:
#                           - weekday string
#                           - seconds of GPS week
#           19-Oct-2004 ss/mm: Bugfix wrt NINT;
#                           '-hms' no longer considered in
#                           relative sense;
#                           list of output parameters returned if
#                           called in list context
#           22-Oct-2004 mm/ss: '-doy' option conform to setday
#           11-Nov-2004 ss: '-l[ocal]' option added;
#                           '-sec' option added;
#                           '%FJ' (fraction of day) output;
#                           '%z' user-defined time stamp format
#           16-Nov-2004 ss: Week-of-year option added;
#                           default output format modified
#           16-Dec-2004 mm: die instead of exit
#           04-Apr-2008 mm: -l now possible for -doy
#           21-Mar-2009 sl: if (defined($LOCAL)) added
#           03-Mar-2011 mm: Full internal precision for MJD
#                           NINT for seconds
#                           Option -p added
#           19-Mar-2013 SL: Use if(@_) instead of if(defined(@_))
#           24-Apr-2014 JD: fixed adding HMS/HID (TIMESET) 
#
# =================================================================

package Gps_Date;

use  Time::Local;
use  Exporter;
use  strict;

@Gps_Date::ISA    = qw(Exporter);
@Gps_Date::EXPORT = qw(gps_date);

my @DAY = ('SU','MO','TU','WE','TH','FR','SA');
my @MON = ('JAN','FEB','MAR','APR','MAY','JUN',
           'JUL','AUG','SEP','OCT','NOV','DEC');
my @ID  = ('A','B','C','D','E','F','G','H','I','J','K','L',
           'M','N','O','P','Q','R','S','T','U','V','W','X','0');

# ---------
sub gps_date {

 my $inp             = " ";
 my $DEBUG           = undef;
 my $LOCAL           = undef;
 my $DATE            = undef;
 my $PREC            = undef;
 my $out             = "%z %F  Doy: %y/%j/%I/%H  Week: %W/%w/%aW%A  MJD: %J%n";
 my ($tmp1, $tmp2, $tmp3, $tmp4) = (undef,undef,undef,undef);
 my ($i, $par);

 if( @_ ) { foreach $par (@_) { $inp .= "$par"." " } }

# Check and Setup Different Inputs  (THE ORDER IS IMPORTANT !)
# --------------------------------

DATESET:

  # set "-VERBOSE"
  if( $inp   =~ / -([vV]*) / ) {
      printf "          -->  -VERB set ! \n";
      $DEBUG = "TRUE";
  }

  # set "-LOCAL"
  if( $inp   =~ / -(L[OCAL]*|l[ocal]*) / ) {
      printf "          -->  -LOCAL set ! \n" if defined($DEBUG);
      $LOCAL = "TRUE";
  }

  # set "-PREC"
  if( $inp   =~ / -([pP]*) / ) {
      printf "          -->  -PREC set ! \n" if defined($DEBUG);
      $PREC = "TRUE";
  }

  # set "-TODAY"
  if( $inp   =~ / -(T[ODAY]*|t[oday]*) / ){
      printf "          --> -TODAY set : Today ! \n" if defined($DEBUG);
      $DATE  = time;
##      ($out) = "Today: "."$out";
      goto TIMESET
  }

  # set "-SEC sec"
  if( $inp =~ / -(SEC|sec)\s*(\d*) /) {
      $DATE = $2;
      goto TIMESET
  }

  # set "-DOY doy"
  if( $inp =~ / -(DOY|doy)\s*([+|-]?\d*)\s*(\d*) /) {
      $tmp4 = $2>0 ? sprintf "%03s", $2 : $2;
      ($tmp1,$tmp2) = gps_date("-t","-o %j %Y");
      $tmp2-- if $tmp4>$tmp1;
      $tmp2 = $3 if $3 ne "";
      if ($tmp4<=0) {
###          if ($LOCAL eq "TRUE") {
          if (defined($LOCAL) && $LOCAL eq "TRUE") {
              $DATE = gps_date("-t","-d $tmp4","-o %U");
          } else {
              $DATE = gps_date("-t","-d $tmp4 -hms 0:00:00","-o %U");
          }
      } else  {
          $DATE = gps_date("-yd $tmp2 $tmp4","-o %U") }
      goto TIMESET
  }

  # set "-MJD Mjd"
  if( $inp   =~ / -(MJD|mjd)\s+(\d\d\d\d\d)([.][\d]*|) / ){
      $tmp2  = sprintf "%i", $2;
      $tmp2 += sprintf "%f", "${3}0"  if ( $3 ne "" );
      printf "          -->   -MJD set : %0.5f \n", $tmp2  if defined($DEBUG);
      $DATE  = ($tmp2 - 40587.00000)*86400;
      goto EVALUATE  if ( $3 ne "" );
      goto TIMESET
  }

  # set "-YMD Year Mn Day"
  if( $inp   =~ / -(YMD|ymd)\s+(\d{2}|\d{4})[-_\s]+(\d{1,2})[-_\s]+(\d{1,2}) / ){
      $tmp2  = set_YEAR($2);
      printf "          -->   -YMD set : %s %s %s \n", $2, $3, $4  if defined($DEBUG);
      $DATE  = timegm(0,0,0,$4,$3-1,$tmp2-1900);
      goto TIMESET
  }

  # set "-YMD Year Mon Day"
  if( $inp   =~ / -(YMD|ymd)\s+(\d{2}|\d{4})[-_\s]*(\w{3})[-_\s]+(\d{1,2}) / ){
      $tmp2  = set_YEAR($2);
      $tmp3  = undef;
      for( $i=0; $i<12; $i++ ){ if( $MON[$i] eq uc($3) ){ $tmp3 = $i; } };
      printf "          --> -YMonD set : %s %s %s \n", $tmp2, $MON[$tmp3], $4 if defined($DEBUG);
      die " Not valid Month = $3 !" unless defined($tmp3);
      $DATE  = timegm(0,0,0,$4,$tmp3,$tmp2-1900);
      goto TIMESET
  }

  # set "-YD Year Doy/Sess"
  if( $inp   =~ / -(YD|yd)\s+(\d{2}|\d{4})[-_\s]*(\d{3,4}|\d{3}[a-xA-X]) / ) {
      printf "          -->    -YD set : %s %s \n", $2, $3 if defined($DEBUG);
      $tmp2  = set_YEAR($2);
      $tmp3  = substr($3,0,3);
      $DATE  = timegm(0,0,0,1,0,$tmp2-1900);
      $DATE += ($tmp3-1)*86400;

      # set also hour
      if( $3 =~ /\d{3}([a-xA-X])/ ){
             printf "          -->    +ID set : %s \n", $1 if defined($DEBUG);
             for( $i=0; $i<=23; $i++ ){
               if( $ID[$i] eq uc($1) ){ $tmp3 = $i; }
             };
             $DATE += $tmp3*3600;
             goto EVALUATE
      }else{ goto TIMESET }
  }

  # set "-WD GPSWeek DoW"
  if( $inp   =~ / -(WD|wd)\s+(\d{4})[-_\s]*(\d{1}) / ) {
      printf "          -->    -WD set : %s %s \n", $2, $3 if defined($DEBUG);
      $DATE  = set_WD($2,$3);
      goto TIMESET
  }

TIMESET:

  # set "-HMS HH:MM:SS" or "-HID HH" (min=0,sec=0 by default)
  if( $inp   =~ / -(HMS|hms)\s+(\d{1,2})[-:\s]+(\d{1,2})[-:\s]+(\d{1,2}) /  or
      $inp   =~ / -(HID|hid)\s+(\d{1,2}) /                                     ) {
      $tmp3=0 unless $tmp3=$3;
      $tmp4=0 unless $tmp4=$4;
      printf "          -->   -HMS set : %s %s %s \n", $2, $tmp3, $tmp4 if defined($DEBUG);
      $DATE  = (defined $DATE) ? int($DATE/86400)*86400 : int(time/86400)*86400;
      $DATE += $2*3600;
      $DATE += $tmp3*60       if defined($tmp3);
      $DATE += $tmp4          if defined($tmp4);
      goto EVALUATE
  }
  # set "-HMS ID:MM:SS" "-HID ID"  (min=0,sec=0 by default)
  if( $inp   =~ / -(HMS|hms)\s+([a-xA-X])[-:\s]+(\d{1,2})[-:\s]+(\d{1,2}) /  or
      $inp   =~ / -(HID|hid)\s+([a-xA-X]) /                                     ) {
      $tmp2  = undef;
      $tmp3=0 unless $tmp3=$3;
      $tmp4=0 unless $tmp4=$4;
      for( $i=0; $i<=23; $i++ ){ if( $ID[$i] eq uc($2) ){ $tmp2 = $i }};
      printf "          --> -HMS set : %s %s %s \n", $tmp2, $tmp3, $tmp4 if defined($DEBUG);
      die " Not valid Hour-ID = $2 !" unless defined($tmp2) ;
      $DATE  = (defined $DATE) ? int($DATE/86400)*86400 : int(time/86400)*86400;
      $DATE += $tmp2*3600;
      $DATE += $3*60       if defined($3);
      $DATE += $4          if defined($4);
      goto EVALUATE
  }


EVALUATE:

  # check the DATE definition !
  # --------------------------
  if( ! defined($DATE) ) { &Usage("$inp") };

  # set "-H +/-hours"
  if( $inp =~ / -[Hh]\s+([()\/\-*+.\d]+) / ) {
      $tmp1 = eval $1;
      printf "          -->  +/- Hours : %i \n", $tmp1 if defined($DEBUG);
      $DATE += $tmp1*3600; }

  # set "-D +/-days"
  if( $inp =~ / -[Dd]\s+([()\/\-*+.\d]+) / ) {
      $tmp1 = eval $1;
      printf "          -->  +/-  Days : %i \n", $tmp1 if defined($DEBUG);
      $DATE += $tmp1*86400; }

  # set "-W +/-weeks"
  if( $inp =~ / -[Ww]\s+([()\/\-*+.\d]+) / ) {
      $tmp1 = eval $1;
      printf "          -->  +/- Weeks : %i \n", $tmp1 if defined($DEBUG);
      $DATE += $tmp1*604800; }

  # set OUTPUT !
  # -----------
  if ($inp =~ /-[Oo]\s+([\s\S]*) / ) {
      printf "          -->    Out set :\"%s\"\n", "$1" if defined($DEBUG);
     ($out) = "$1"; }



  # Get the dates
  # -------------
  $DATE = NINT($DATE);
  my $T = defined($LOCAL) ? localtime($DATE) : gmtime($DATE);
  my @T = defined($LOCAL) ? localtime($DATE) : gmtime($DATE);


  # set variables
  my $sec   = sprintf "%s",    $T[0] ;
  my $sec_  = sprintf "%2s",   $T[0] ;
  my $sec0  = sprintf "%02s",  $T[0] ;

  my $min   = sprintf "%s",    $T[1] ;
  my $min_  = sprintf "%2s",   $T[1] ;
  my $min0  = sprintf "%02s",  $T[1] ;

  my $hour  = sprintf "%s",    $T[2] ;
  my $hour_ = sprintf "%2s",   $T[2] ;
  my $hour0 = sprintf "%02s",  $T[2] ;
  my $id    = sprintf "%1s",   $ID[$T[2]] ;

  my $dd    = sprintf "%s",    $T[3] ;
  my $dd_   = sprintf "%2s",   $T[3] ;
  my $dd0   = sprintf "%02s",  $T[3] ;

  my $doy   = sprintf "%s",    $T[7]+1 ;   # T[7] = [0-365] !
  my $doy_  = sprintf "%3s",   $T[7]+1 ;
  my $doy0  = sprintf "%03s",  $T[7]+1 ;

  my $mm    = sprintf "%s",    $T[4]+1 ;   # T[4] = [0-11] !
  my $mm_   = sprintf "%2s",   $T[4]+1 ;
  my $mm0   = sprintf "%02s",  $T[4]+1 ;
  my $mon   = sprintf "%3.3s", $MON[$mm-1];

  my $yyyy  = sprintf "%4s",   $T[5]+1900 ; # T[5] = [YEAR-1900] !
  my $yy    = substr($yyyy,-2,2)          ;

  my $dow   = sprintf "%1s",    $T[6] ;
  my $dowstr= sprintf "%2.2s",  $DAY[$T[6]];

  my $mjdHlp = MJD($yyyy,$mm,$dd,$hour,$min,$sec);
  my $mjd   = sprintf "%11.5f", $mjdHlp;
  my $mjdfrc= sprintf "%7.5f",  $mjdHlp-int($mjdHlp);
  my $mjdint= sprintf "%5i",    $mjdHlp;
  if (defined($PREC)) {
      $mjd   = $mjdHlp;
      $mjdfrc= $mjdHlp-int($mjdHlp);
  }

  my ($week,$weeksec) = WEEK($mjd);
     $week     = sprintf "%s",   $week;
     $weeksec  = sprintf "%s",   $weeksec;
  my $week_    = sprintf "%4s",  $week;
  my $weeksec_ = sprintf "%6s",  $weeksec;
  my $week0    = sprintf "%04s", $week;
  my $weeksec0 = sprintf "%06s", $weeksec;

  my ($woy,$yow) = WOY($yyyy,$mm,$dd);
     $woy      = sprintf "%s",   $woy;
     $yow      = sprintf "%s",   $yow;
  my $woy_     = sprintf "%2s",  $woy;
  my $yow_     = sprintf "%2s",  $yow;
  my $woy0     = sprintf "%02s", $woy;
  my $yow0     = sprintf "%02s", $yow;

  # substitute user-defined time stamp (for processing protocols)
  $out =~ s|%z|%d-%C-%Y %Z|g;#  full Date and Time  [DD-MON-YYYY HH:MM:SS]

  # substitute special outputs
  $out =~ s|%V|%X %Z|g     ; #  full Date and Time  [YYYY-MM-DD HH:MM:SS]
  $out =~ s|%v|%x %Z|g     ; #  full Date and Time  [YYYY-MON-DD HH:MM:SS]
  $out =~ s|%X|%Y-%m-%d|g  ; #  full Date           [YYYY-MM-DD]
  $out =~ s|%x|%Y-%B-%d|g  ; #  full Date           [YYYY-MON-DD]
  $out =~ s|%Z|%H:%M:%S|g  ; #  full Time           [HH:MM:SS]
  $out =~ s|%U|$DATE|g     ; #  number of Seconds since 1.1.1970


  # substitute Date
  $out =~ s|%Y|$yyyy|g     ; #   [195?-203?] .. year
  $out =~ s|%y|$yy|g       ; #       [00-99] .. year = last 2 digits

  $out =~ s|%b|\L$mon|g    ; #     [jan-dec] .. month [lower case]
  $out =~ s|%B|\U$mon|g    ; #     [JAN-DEC] .. month [upper case]
  $out =~ s|%C|\L\u$mon|g  ; #     [Jan-Dec] .. month [capitalize]

  $out =~ s|%m|$mm0|g      ; #       [01-12] .. month
  $out =~ s|%_m|$mm_|g     ; #       [ 1-12] .. month
  $out =~ s|%:m|$mm|g      ; #        [1-12] .. month

  $out =~ s|%d|$dd0|g      ; #       [01-31] .. day
  $out =~ s|%_d|$dd_|g     ; #       [ 1-31] .. day
  $out =~ s|%:d|$dd|g      ; #        [1-31] .. day

  $out =~ s|%j|$doy0|g     ; #     [001-365] .. DoY
  $out =~ s|%_j|$doy_|g    ; #     [  1-365] .. DoY
  $out =~ s|%:j|$doy|g     ; #       [1-365] .. DoY

  $out =~ s|%J|$mjd|g      ; # [?????.?????] .. Modif.Jul.Date
  $out =~ s|%IJ|$mjdint|g  ; # [?????]       .. Modif.Jul.Date [integer]
  $out =~ s|%FJ|$mjdfrc|g  ; # [0.??????]    .. Modif.Jul.Date [fraction]

  $out =~ s|%w|$dow|g      ; #         [0-6] .. DoW
  $out =~ s|%e|\L$dowstr|g ; #       [su-sa] .. DoW [lower case]
  $out =~ s|%E|\U$dowstr|g ; #       [SU-SA] .. DoW [upper case]
  $out =~ s|%F|\L\u$dowstr|g;#       [Su-Sa] .. DoW [capitalize]

  $out =~ s|%W|$week0|g    ; #   [0000-????] .. GPS Week
  $out =~ s|%_W|$week_|g   ; #   [   0-????] .. GPS Week
  $out =~ s|%:W|$week|g    ; #      [0-????] .. GPS Week

  $out =~ s|%G|$weeksec0|g ; # [000000-??????] .. GPS Week Seconds
  $out =~ s|%_G|$weeksec_|g; # [     0-??????] .. GPS Week Seconds
  $out =~ s|%:G|$weeksec|g ; #      [0-??????] .. GPS Week Seconds

  $out =~ s|%A|$woy0|g     ; #       [01-53] .. DIN Week
  $out =~ s|%_A|$woy_|g    ; #       [ 1-53] .. DIN Week
  $out =~ s|%:A|$woy|g     ; #        [1-53] .. DIN Week

  $out =~ s|%a|$yow0|g     ; #       [00-99] .. DIN Week Year
  $out =~ s|%_a|$yow_|g    ; #       [ 0-99] .. DIN Week Year
  $out =~ s|%:a|$yow|g     ; #        [0-99] .. DIN Week Year

  # substitute Time
  $out =~ s|%H|$hour0|g    ; #       [00-23] .. hour
  $out =~ s|%_H|$hour_|g   ; #       [ 0-23] .. hour
  $out =~ s|%:H|$hour|g    ; #        [0-23] .. hour

  $out =~ s|%I|\U$id|g     ; #       [A-Z,0] .. hour ID -> A=00,B=01,..,Z=23,0=24
  $out =~ s|%i|\L$id|g     ; #       [a-z,0] .. hour ID -> a=00,b=01,..,z=23,0=24

  $out =~ s|%M|$min0|g     ; #       [00-59] .. minute
  $out =~ s|%_M|$min_|g    ; #       [ 0-59] .. minute
  $out =~ s|%:M|$min|g     ; #        [0-59] .. minute

  $out =~ s|%S|$sec0|g     ; #       [00-59] .. second
  $out =~ s|%_S|$sec_|g    ; #       [ 0-59] .. second
  $out =~ s|%:S|$sec|g     ; #        [0-59] .. second

  # substitute Special Characters
  $out =~ s|%n|\n|g        ; #  newline
  $out =~ s|%t|\t|g        ; #  tabulator
  $out =~ s|[%]+|%%|g      ; #  substite doubled to single '%%' -> '%'


  return wantarray ? split(" ",$out) : $out;
}


# ==================================================================================
# INTERNAL SUBROUTINES

# usage
# ---------------------
sub Usage {
format STDERR =

 Usage: gps_date <[ -ymd | -yd | -wd | -mjd | -doy DATSTR ] [ -t[today] ]>
                  [ -hms | -hid             TIMSTR ]
                  [ -h   | -d  | -w         +/-INT ]
                  [ -o                      OUTSTR ]
                  [ -v   ]


 Supported DATSTR: -ymd  ..  yy|yyyy   mm|mon   dd       with delimiters [-_\s]+
                   -yd   ..  yy|yyyy  doy|sess|doyid     with delimiters [-_\s]+
                   -mjd  ..  ddddd[.ddddd]
                   -wd   ..  wwww d                      with delimiters [-_\s]+
                   -doy  ..  doy                         may be negative
           TIMSTR: -hms  ..  hh|id mm ss                 with delimiters [-:\s]+
                   -hid  ..  hh|id                       work for hours only
           OUTSTR: -o    ..  any text + spec.chars


 Spec. chars: year    = %y %Y       = [00-99] [1999]
              month   = %m %b %B %C = [01-12] [jan-dec] [JAN-DEC] [Jan-Dec]
              day     = %d          = [01-31]
              doy     = %j          = [001-365]
              dow     = %w %e %E %F = [0-6] [su-sa] [SU-SA] [Su-Sa]
              gpsweek = %W          = [0-????]
              gpssec  = %G          = [0-??????]
              woy     = %A          = [01-53]
              yow     = %a          = [00-99]
              modjul  = %J          = [?????.?????]
              modjul  = %IJ         = [?????]
              modjul  = %FJ         = [0.?????]
              hour,id = %H %I %i    = [00-23]  [A-X] [a-x]  (A=00,..,X=23)
              min     = %M          = [00-59]
              sec     = %S          = [00-59]

              dattim  = %V %v       = [YYYY-MM-DD HH:MM:SS] [YYYY-MON-DD HH:MM:SS]
              dat     = %X %x       = [YYYY-MM-DD]          [YYYY-MON-DD]
              tim     = %Z          = [HH:MM:SS]
              timprt  = %z          = [DD-MON-YYYY HH:MM:SS]
              seconds = %U          = seconds from 1.1.1970

              spec    = %t %n %%    = "\tab" "\newline" "%"
              pads    = %: %_       = "any_pad","blank_pad", (default="0_pad")

.

  write STDERR;
##  die;
  exit 1;
}

# validate YEAR
# ---------------------
sub set_YEAR {
  my ($yr) = @_;
  my $year;
  if(    $yr > 100 ) { $year = $yr; }
  elsif( $yr >  70 ) { $year = $yr+1900 }
  else               { $year = $yr+2000 };
  return $year;
}

# nearest integer
# ---------------
sub NINT {
  my $A = shift;
  if ( $A >= 0 ) { return int($A + 0.5) }
  if ( $A <  0 ) { return int($A - 0.5) } }
;

# set using GPSWEED DOW
# ---------------------
sub set_WD {
   my ($WEEK,$DOW) = @_;
   my $MJD =  $WEEK * 7.0 + $DOW + 44244.0              ;
   my $t1  =  1.0 + $MJD - MOD( $MJD, 1.0 ) + 2400000.0 ;
   my $t4  =  MOD( $MJD, 1.0 )                          ;
   my $ih  =  NINT( ($t1 - 1867216.25)/36524.25 )       ;
   my $t2  =  $t1 + 1 + $ih - $ih/4                     ;
   my $t3  =  $t2 - 1720995.0                           ;
   my $ih1 =  int( ($t3 - 122.1)/365.25 )               ;
      $t1  =  $ih1*365.25 - MOD( $ih1*365.25, 1.0 )     ;
   my $ih2 =  int( ($t3 - $t1)/30.6001 )                ;
   my $dd  =  $t3 - $t1 - int( $ih2*30.6001 ) + $t4     ;
   my $mm  =  $ih2 - 1                                  ;
      if( $ih2 > 13 ){ $mm = $ih2 - 13 }                ;
   my $jj  = $ih1                                       ;
      if( $mm <=  2 ){ $jj = $jj + 1 }                  ;
   return timegm(0,0,0,$dd,$mm-1,$jj-1900);
}


# Calculate GPS week (and number of seconds)
# ------------------------------------------
sub WEEK {
  my ($MJD) = @_;
  my $tmp = ($MJD-44244)/7;
  my $week = int($tmp);
  my $weeksec = NINT(($tmp-$week)*604800);
  return wantarray ? ($week,$weeksec) : $week;
}


# Calculate week of year (and corresponding year)
# -----------------------------------------------
sub WOY {
  my ($yyyy,$mm,$dd) = @_;
  my $mjd = MJD($yyyy,$mm,$dd,0,0,0);
  my $dow = MOD($mjd-5,7)+1;
  my $mjd_th = $mjd-$dow+4;
  my $yow = $yyyy;
  if    ($mjd_th< MJD($yyyy  ,1,1,0,0,0)) { $yow-- }
  elsif ($mjd_th>=MJD($yyyy+1,1,1,0,0,0)) { $yow++ }
  my $mjd_0 = MJD($yow,1,1,0,0,0);
  my $woy = int(($mjd_th-$mjd_0+7)/7);
  $yow = MOD($yow,100);
  return wantarray ? ($woy,$yow) : $woy;
}


# Modulo
# ---------------------
sub MOD {  my ($a1, $a2) = @_ ;
           return ($a1 - int($a1 / $a2) * $a2);
}


# calculate Mod.Jul.Date
# ---------------------
sub MJD {
   my ($yyyy, $mm, $dd, $hr, $mi, $sc) = @_;
   my $D_hr = $hr / 24    ;
   my $D_mi = $mi / 1440  ;
   my $D_sc = $sc / 86400 ;
   my $M    = $mm         ;
   my $Y    = $yyyy       ;

   if( $mm<=2 ){ $M = $mm   + 12 ;
                 $Y = $yyyy -  1 ;
   }
   my $MJD  = $Y*365.25 - MOD( $Y*365.25 , 1 ) - 679006                 ;
      $MJD += int(30.6001*($M+1)) + 2 - int($Y/100) + int($Y/400) + $dd ;
      $MJD += ${D_hr} + ${D_mi} + ${D_sc}                               ;
   return $MJD ;
}

1;
__END__
