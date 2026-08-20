#!/usr/bin/perl
# -----------------------------------------------------------------------------
# (c) 2011 Geodetic Observatory Pecny, http://www.pecny.cz (gnss@pecny.cz)
#     Research Institute of Geodesy, Topography and Cartography
#     Ondrejov 244, 251 65, Czech Republic
#
#  Purpose: script for extracting Anubis QC protocols
#
#  2015-01-10 /JD: created
#
# -----------------------------------------------------------------------------
package Anub_Xtr;

use Exporter;
use File::Basename qw( dirname );
use lib dirname (__FILE__);
use Gps_Date;
use strict;

@Anub_Xtr::ISA    = qw( Exporter );
@Anub_Xtr::EXPORT = qw( $VERS $NSAT %GNSS @GNSS $GNSS $NULL
                        xtr_file );

our( $NULL ) = "xxxx-xx-xx xx:xx:xx";                    
our( %GNSS ) = ( 'G' => "GPS", 'R' => "GLO", 'E' => "GAL", 'C' => "BDS", 'S' => "SBS", 'J' => "QZS" );
our( @GALL ) = qw( GPS GLO GAL BDS SBS QZS );
our( @GNSS ) = ();
our( @GNSC ) = ();
our( $VERS ) = "x.x.x";
our( $NSAT ) = -1;
# our( @SECT ) = qw( SUM HDR GAP PRE EST OBS BND ELE MPT SNR );


my @CODES;
my %SEC;
my $SEC;

my $idxHDR = -1;
my $date = '\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d'; # ":00" hours
my $vers = '[(v.]+(\d)[)]';
my $real = '[+\-.\d]+';
my $gnss = join '|',@GALL;
my $gnsC = "[GRECSJ]";
my $intg = '[+\-\d]+';


# SINGLE FILE (SECTIONS)
# -------
sub xtr_file {
  my( $file, $DATA, $opt ) = @_;
  
  $DATA->{"FIL"} = $file;
  my %rGNSS = reverse %GNSS;
  foreach my $gns ( @GALL ){
    if( $opt->{$gns} > 0 ){ push( @GNSS, $gns ); push( @GNSC, $rGNSS{$gns} ); }
    else{ printf STDERR "# $gns excluded on request\n"; }
  }
  ( $gnss ) = join '|', @GNSS;
  ( $gnsC ) = join '|', @GNSC;
# printf " @GNSS  @GNSC\n";

  open( IFIL, "$file" );

  my $irc = 0;
  my $line = <IFIL> || printf STDERR " *** Cannot open file: $file\n";

  if( $line =~ m|# G-Nut/Anubis.* \[(\d+.\d+)\] |          ||
      $line =~ m|# G-Nut/Anubis.* \[(\d+.[Xx])\] |         ||
      $line =~ m|# G-Nut/Anubis.* \[(\d+.\d+.[Xx])\] |     ||
      $line =~ m|# G-Nut/Anubis.* \[(\d+.\d+.\d+).*\] |    ||
      $line =~ m|# G-Nut/Anubis.* \[(\d+.\d+.[Bb]eta).*\] | ){ $VERS = "$1"; }
  else{ printf " *** Not Anubis extraction \n"; return -1; }

  while( $line = <IFIL> ){ # printf "$line";

    if( $irc < 0 ){ return -1; }

    # SECTIONS ID
    if( $line =~ m|#==+| ){
             
      # FIRST RESET ALL (NOT GIVEN ORDER)
      foreach my $sec ( keys %SEC ){ $SEC{$sec} = 0; }

      # SELECT NEW SECTION
      if( $line =~ m|#=+ Summ.* ($vers)| ){ $SEC{'SUM'} = $2; next; }
      if( $line =~ m|#=+ Head.* ($vers)| ){ $SEC{'HDR'} = $2; next; }
      if( $line =~ m|#=+ Gaps.* ($vers)| ){ $SEC{'GAP'} = $2; next; }
      if( $line =~ m|#=+ Prep.* ($vers)| ){ $SEC{'PRE'} = $2; next; }
      if( $line =~ m|#=+ Esti.* ($vers)| ){ $SEC{'EST'} = $2; next; }
      if( $line =~ m|#=+ Obse.* ($vers)| ){ $SEC{'OBS'} = $2; next; }
      if( $line =~ m|#=+ Band.* ($vers)| ){ $SEC{'BND'} = $2; next; }
      if( $line =~ m|#=+ Elev.* ($vers)| ){ $SEC{'ELE'} = $2; next; }
      if( $line =~ m|#=+ Code.* ($vers)| ){ $SEC{'MPT'} = $2; next; }
      if( $line =~ m|#=+ Sign.* ($vers)| ){ $SEC{'SNR'} = $2; next; }
      if( $line =~ m|#=+ Iono.* S4C.* ($vers)| ){ $SEC{'S4C'} = $2; next; }  # no scaling applied
      if( $line =~ m|#=+ Iono.* ROT.* ($vers)| ){ $SEC{'ROT'} = $2; next; }  # no scaling applied
   }

    # DECODE FILE SECTION
    if(    exists $SEC{'SUM'} && $SEC{'SUM'} > 0 ){ $irc = &xtr_summ($line, $DATA, $opt); next; }
    elsif( exists $SEC{'HDR'} && $SEC{'HDR'} > 0 ){ $irc = &xtr_head($line, $DATA, $opt); next; }
    elsif( exists $SEC{'GAP'} && $SEC{'GAP'} > 0 ){ $irc = &xtr_gaps($line, $DATA, $opt); next; }
    elsif( exists $SEC{'PRE'} && $SEC{'PRE'} > 0 ){ $irc = &xtr_prep($line, $DATA, $opt); next; }
    elsif( exists $SEC{'EST'} && $SEC{'EST'} > 0 ){ $irc = &xtr_esti($line, $DATA, $opt); next; }
    elsif( exists $SEC{'OBS'} && $SEC{'OBS'} > 0 ){ $irc = &xtr_stat($line, $DATA, $opt); next; }
    elsif( exists $SEC{'ELE'} && $SEC{'ELE'} > 0 ){ $irc = &xtr_elev($line, $DATA, $opt); next; }
    elsif( exists $SEC{'BND'} && $SEC{'BND'} > 0 ){ $irc = &xtr_band($line, $DATA, $opt); next; }
    elsif( exists $SEC{'MPT'} && $SEC{'MPT'} > 0 ){ $irc = &xtr_path($line, $DATA, $opt); next; }
    elsif( exists $SEC{'SNR'} && $SEC{'SNR'} > 0 ){ $irc = &xtr_snrt($line, $DATA, $opt); next; }
    elsif( exists $SEC{'S4C'} && $SEC{'S4C'} > 0 ){ $irc = &xtr_s4ci($line, $DATA, $opt); next; }
    elsif( exists $SEC{'ROT'} && $SEC{'ROT'} > 0 ){ $irc = &xtr_roti($line, $DATA, $opt); next; }
#   else{                      &xtr_none() }
      
  }
  close( IFIL );
  return 0;
}

# SUMMARY
# -------
sub xtr_summ {
  my( $line, $DATA, $opt ) = @_;

  # Total summary single line
  if( $line =~ /^=TOTSUM ($date) ($date) \s*(.*)$/ 
  ){
    my $dat  = "$1";
    my(@rec) = split('\s+', $3);
    $DATA->{"TOT"}{"RefDat"} = $dat;
    $DATA->{"TOT"}{"Hours"}  = $rec[0];
    $DATA->{"TOT"}{"Sample"} = $rec[1];
    $DATA->{"TOT"}{"MinEle"} = $rec[2];
    $DATA->{"TOT"}{"nGNSS"}  = 0;
  }
    
  # GNSS-specific summary lines
  if( $line =~ /^=($gnss)(SUM) ($date) \s*(.*)$/
  ){
    my $gns = $1;
    my $key = $2;
    my $dat = $3;
    my(@rec) = split('\s+', $4);
    $DATA->{"TOT"}{"nGNSS"} += 1;

    $DATA->{"SUM1"}{$gns}{"EPO"}{"ExpEpo"} = $rec[0];
    $DATA->{"SUM1"}{$gns}{"EPO"}{"HavEpo"} = $rec[1];
    $DATA->{"SUM1"}{$gns}{"EPO"}{"UseEpo"} = $rec[2];
    $DATA->{"SUM1"}{$gns}{"EPO"}{"xCoEpo"} = $rec[3];
    $DATA->{"SUM1"}{$gns}{"EPO"}{"xPhEpo"} = $rec[4];
    $DATA->{"SUM1"}{$gns}{"SAT"}{"xCoSat"} = $rec[5];
    $DATA->{"SUM1"}{$gns}{"SAT"}{"xPhSat"} = $rec[6];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"xcsAll"} = $rec[7];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"xcsEpo"} = $rec[8];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"xcsSat"} = $rec[9];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"xcsSig"} = $rec[10];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"numSlp"} = $rec[11];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"numJmp"} = $rec[12];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"numGap"} = $rec[13];
    $DATA->{"SUM1"}{$gns}{"XCS"}{"numPcs"} = $rec[14];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp1"}    = $rec[15];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp2"}    = $rec[16];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp3"}    = $rec[17];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp4"}    = $rec[18];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp5"}    = $rec[19];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp6"}    = $rec[20];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp7"}    = $rec[21];
    $DATA->{"SUM1"}{$gns}{"MPT"}{"mp8"}    = $rec[22];

    $DATA->{"SUM0"}{$gns}{"SAT"}{"maxSat"} = 0;          # max over GNSS
    $DATA->{"SUM0"}{$gns}{"OBS"}{"maxObs"} = 0;          # max over GNSS
    return 0;
  }
  
  # keys for Elev-histograms
  if( $line =~ /^#GNSxxx ($date) \s*(.*)$/
  ){
    my(@rec) = split('\s+', $2);
    for(my $i = 7; $i < scalar @rec; $i++){
      $DATA->{"SUM0"}{"GNS"}{"ELE"}{$i} = "$rec[$i]";
    }
    return 0;
  }

  # keys for Sign-specific lines
  if( $line =~ /^=($gnss)([A-Z][A-Z0-9].) ($date) \s*(.*)$/
  ){
    my $gns = $1;
    my $key = $2;
    my $dat = $3;
    my(@rec) = split('\s+', $4);

    $DATA->{"SUM0"}{$gns}{"SAT"}{"maxSat"} = $rec[0] if $rec[0] ne "-" && $DATA->{"SUM0"}{$gns}{"SAT"}{"maxSat"} < $rec[0]; # GNS maxSat
    $DATA->{"SUM0"}{$gns}{"OBS"}{"maxObs"} = $rec[1] if $rec[1] ne "-" && $DATA->{"SUM0"}{$gns}{"OBS"}{"maxObs"} < $rec[1]; # GNS maxObs
    $DATA->{"SUM0"}{$gns}{"OBS"}{"maxObs"} = $rec[2] if                   $DATA->{"SUM0"}{$gns}{"OBS"}{"maxObs"} == 0;      # GNS maxHav
      
    $DATA->{"SUM2"}{$gns}{$key}{"nSatel"} = $rec[0];
    $DATA->{"SUM2"}{$gns}{$key}{"expObs"} = ($rec[1] ne "-" ) ? $rec[1] : 0;
    $DATA->{"SUM2"}{$gns}{$key}{"havObs"} = ($rec[2] ne "-" ) ? $rec[2] : 0;
    $DATA->{"SUM2"}{$gns}{$key}{"pctObs"} = ($rec[3] ne "-" ) ? $rec[3] : 0.0;
    $DATA->{"SUM2"}{$gns}{$key}{"norObs"} = ($rec[3] ne "-" ) ? $rec[3] : 0.0;
    $DATA->{"SUM2"}{$gns}{$key}{"expCut"} = ($rec[4] ne "-" ) ? $rec[4] : 0;
    $DATA->{"SUM2"}{$gns}{$key}{"havCut"} = ($rec[5] ne "-" ) ? $rec[5] : 0;
    $DATA->{"SUM2"}{$gns}{$key}{"pctCut"} = ($rec[6] ne "-" ) ? $rec[6] : 0.0;
    $DATA->{"SUM2"}{$gns}{$key}{"norCut"} = ($rec[6] ne "-" ) ? $rec[6] : 0.0;

    foreach my $i ( sort{$a<=>$b} keys %{$DATA->{SUM0}{GNS}{ELE}} ){
      $DATA->{"SUM2"}{$gns}{$key}{$i} = $rec[$i];
    }
    #### normalize percentage
    if( $DATA->{"SUM2"}{$gns}{$key}{"nSatel"} > 0 ){ # $DATA->{"SUM2"}{$gns}{$key}{"nSatel"} > 0 ){
      my $norm = $DATA->{"SUM2"}{$gns}{$key}{"nSatel"} / $DATA->{"SUM0"}{$gns}{"SAT"}{"maxSat"};
      $DATA->{"SUM2"}{$gns}{$key}{"norObs"} *= $norm if $DATA->{"SUM2"}{$gns}{$key}{"norObs"} ne "-" ;
      $DATA->{"SUM2"}{$gns}{$key}{"norCut"} *= $norm if $DATA->{"SUM2"}{$gns}{$key}{"norCut"} ne "-" ;
    }
  }
  return 0;
}


# HEADER
# -------
sub xtr_head {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m|_RINEX_HEADER|g ){ $idxHDR = index($line,"_RINEX_HEADER"); return 0; }

  # site maker
  if( $line =~ m|MARKER| ){
     $DATA->{"SIT"} = uc(substr($line, $idxHDR, 4));
     $DATA->{"SIT"} =~ s|\s+|_|g;
     $DATA->{"SIT"} =~ s|[.]|-|g;
     $DATA->{"SIT"} =~ s|_$||g;
     if( $opt->{"SIT"} ){ printf "$DATA->{'SIT'}\n"; exit(0); }
      
  # receiver
  }elsif( $line =~ m|RECEIV| ){
     $DATA->{"REC"} = uc(substr($line, $idxHDR, 20));
     $DATA->{"REC"} =~ s|\s+|_|g;
     $DATA->{"REC"} =~ s|[.]|-|g;
     $DATA->{"REC"} =~ s|_$||g;
     if( $opt->{"REC"} ){ printf "$DATA->{'REC'}\n"; exit(0); }
     
  # antenna
  }elsif( $line =~ m|ANTENN| ){
     $DATA->{"ANT"} = uc(substr($line, $idxHDR, 20));
     $DATA->{"ANT"} =~ s|\s+|_|g;
     $DATA->{"ANT"} =~ s|[.]|-|g;
     $DATA->{"ANT"} =~ s|_$||g;
     if( $opt->{"ANT"} ){ printf "$DATA->{'ANT'}\n"; exit(0); }
  }
  return 0;
}

# GAPS & PIECES
# -------
sub xtr_gaps {
  my( $line, $DATA, $opt ) = @_;
  return 0;
}

# PREPROC
# -------
sub xtr_prep {
  my( $line, $DATA, $opt ) = @_;
  return 0;
}

# ESTIMATE
# -------
sub xtr_esti {
  my( $line, $DATA, $opt ) = @_;
  $SEC = "EST";

  if( $line =~ /^=(XYZ|BLH)($gnss) ($date) \s*(.*)$/
#      $line =~ /^=(XYZ|BLH)($gnss) ($date) \s*($real) \s*($real) \s*($real) \s*($real) \s*($real) \s*($real) \s*($real) \s*($real) \s*($intg) \s*($intg)/
  ){
    my $key = $1;
    my $gns = $2;
    my $dat = $3;
    my(@rec) = split('\s+', $4);

    $DATA->{"POS"}{$gns}{"EST"}{substr($key,0,1)} = $rec[0];
    $DATA->{"POS"}{$gns}{"EST"}{substr($key,1,1)} = $rec[1];
    $DATA->{"POS"}{$gns}{"EST"}{substr($key,2,1)} = $rec[2];
    $DATA->{"POS"}{$gns}{"RMS"}{substr($key,0,1)} = $rec[3];
    $DATA->{"POS"}{$gns}{"RMS"}{substr($key,1,1)} = $rec[4];
    $DATA->{"POS"}{$gns}{"RMS"}{substr($key,2,1)} = $rec[5];
    $DATA->{"POS"}{$gns}{"USE"}{substr($key,0,3)} = $rec[6];
    $DATA->{"POS"}{$gns}{"XCL"}{substr($key,0,3)} = $rec[7];
  }

  if( $line =~ /^ (POS)($gnss) ($date) \s*(.*)$/
  ){
    my $key = $1;
    my $gns = $2;
    my $dat = $3;
    my(@rec) = split('\s+', $4);

    $DATA->{$SEC}{$gns}{$key}{$dat}{"X"}   = $rec[0];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"Y"}   = $rec[1];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"Z"}   = $rec[2];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"B"}   = $rec[3];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"L"}   = $rec[4];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"H"}   = $rec[5];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"DOP"} = $rec[6];
    $DATA->{$SEC}{$gns}{$key}{$dat}{"DOP"} = 9999.0 if( ! defined $rec[6]);
  }
  return 0;
}

# OBSERV
# -------
sub xtr_stat {
  my( $line, $DATA, $opt ) = @_;
  if( $line =~ /^=GNSSYS $date \s*($intg) \s*(.*)$/ )
  {
    my $nGNS  = $1;
#    ( @GNSS ) = split '\s+', $2;
#    ( $gnss ) = join '|',@GNSS;

    # just return gnss system info & exists
    if( $opt->{'GNS'} == 1 ){ printf "%i: %s\n", $nGNS, join ' ',@GNSS; return -1; } # exit 1;
  }
  # observations (GNS signals)
  elsif( $line =~ /^ ($gnsC)(\d\d)OBS ($date) \s*($intg) \s*(.+)$/ )
  {
    my( $key, $gns, $prn, $dat, $cnt, $val ) = ("$1$2", $1, $2, $NULL, $4, $5);
    my( @split ) = split '\s+', $val;
    my $svn = sprintf "%i", substr $prn,1,2;

    foreach my $cod ( @split ){
       push(@CODES, $cod) if ! grep(/$cod/,@CODES);
       $DATA->{"OBS"}{$gns}{"$key:$cod"}{$dat}{$svn} = $cod;
    }
  }
  return 0;
}

# BANDS
# -------
sub xtr_band {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m/^ ($gnss)([LC]BN) / and
      $line =~ m/^ ($gnss)([LC]BN) ($date) \s*($real) \s*(.+)$/ )
  {
    my( $gns, $key, $dat, $cnt, $val ) = ($1, $2, $3, $4, $5);
    my( @split ) = split '\s+', $val;  # printf "split = @split\n";

    for(my $i=1; $i <= scalar @split; $i++){
      if( $split[$i-1] eq "-" ){ 
        $DATA->{"BND"}{$gns}{$key}{$dat}{$i} = 0;
	  
      }else{
        $DATA->{"BND"}{$gns}{$key}{$dat}{$i}  = $split[$i-1];

        if( !defined         $DATA->{"BND"}{$gns}{$key}{$NULL}{$i} ||
	    $split[$i-1] gt  $DATA->{"BND"}{$gns}{$key}{$NULL}{$i}  
	){
           $DATA->{"BND"}{$gns}{$key}{$NULL}{$i} = $split[$i-1];
        };
      }

    }
  }elsif( $line =~ m/^ ($gnss)(XBN) / and
          $line =~ m/^ ($gnss)(XBN) ($date) \s*$intg \s*$intg \s*$intg \s*(.+)$/ )
  {
    my( $gns, $key, $dat, $val ) = ($1, $2, $3, $4);
    my( @split ) = split '\s+', $val;
  
    foreach my $sat ( @split ){
      $DATA->{"BND"}{$gns}{$key}{$dat}{"0"}  = scalar @split;
    }
  }
  return 0;
}

# SKYPLOT
# -------
sub xtr_elev {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m/^ ($gnss)(ELE|AZI) ($date) \s*($real) \s*(.+)$/ )
  {
    my( $gns, $key, $dat, $cnt, $val ) = ( $1, $2, $3, $4, $5 );
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=1; $i<=$NSAT; $i++){ $DATA->{"SKY"}{$gns}{$key}{$dat}{$i} = $split[$i-1]; }
   }
  return 0;
}

# MULTIPATH
# -------
sub xtr_path {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m/^=($gnss)(M[1-9][A-Z]) ($date) \s*(.+)$/ ||
      $line =~ m/^=($gnss)(M[A-Z][1-9]) ($date) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $val ) = ("$1$2", $1, $2, $3, $4);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=0; $i<=$NSAT; $i++){ $DATA->{"MPT"}{$gns}{$key}{$NULL}{$i} = $split[$i];
      if( $i == 0 && $split[$i] eq '-' ){ $DATA->{"MPT"}{$gns}{$key}{$NULL}{$i} = 0.0; } # null value!
    }
  }      

  if( $line =~ m/^ ($gnss)(M[1-9][A-Z]) ($date) \s*($real) \s*(.+)$/ ||
      $line =~ m/^ ($gnss)(M[A-Z][1-9]) ($date) \s*($real) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $cnt, $val ) = ("$1$2", $1, $2, $3, $4, $5);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=1; $i<=$NSAT; $i++){ $DATA->{"MPT"}{$gns}{$key}{$dat}{$i} = $split[$i-1]; }
  }      
  return 0;
}

# SNR
# -------
sub xtr_snrt {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m/^=($gnss)(S[1-9][A-Z]) ($date) \s*(.+)$/ ||
      $line =~ m/^=($gnss)(S[A-Z][1-9]) ($date) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $val ) = ("$1$2", $1, $2, $3, $4);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=0; $i<=$NSAT; $i++){ $DATA->{"SNR"}{$gns}{$key}{$NULL}{$i} = $split[$i];
      if( $i == 0 && $split[$i] eq '-' ){ $DATA->{"SNR"}{$gns}{$key}{$NULL}{$i} = 0.0; } # null value!
    }
  }      

  if( $line =~ m/^ ($gnss)(S[1-9][A-Z]) ($date) \s*($real) \s*(.+)$/ ||
      $line =~ m/^ ($gnss)(S[A-Z][1-9]) ($date) \s*($real) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $cnt, $val ) = ("$1$2", $1, $2, $3, $4, $5);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=1; $i<=$NSAT; $i++){ $DATA->{"SNR"}{$gns}{$key}{$dat}{$i} = $split[$i-1]; }
  }      
  return 0;
}

# S4C
# -------
sub xtr_s4ci {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m/^=($gnss)(S4C|IDX) ($date) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $val ) = ("$1$2", $1, $2, $3, $4);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=0; $i<=$NSAT; $i++){ $DATA->{"S4C"}{$gns}{$key}{$NULL}{$i} = $split[$i];
      if( $i == 0 && $split[$i] eq '-' ){ $DATA->{"S4C"}{$gns}{$key}{$NULL}{$i} = 0.0; } # null value!
    }
  }      

  if( $line =~ m/^ ($gnss)(S4C|IDX) ($date) \s*($real) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $cnt, $val ) = ("$1$2", $1, $2, $3, $4, $5);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=1; $i<=$NSAT; $i++){ $DATA->{"S4C"}{$gns}{$key}{$dat}{$i} = $split[$i-1]; }
  }      
  return 0;
}

# ROT
# -------
sub xtr_roti {
  my( $line, $DATA, $opt ) = @_;

  if( $line =~ m/^=($gnss)(ROT) ($date) \s*(.+)$/ )
  { printf $line;
    my( $key, $gns, $col, $dat, $val ) = ("$1$2", $1, $2, $3, $4);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=0; $i<=$NSAT; $i++){ $DATA->{"ROT"}{$gns}{$key}{$NULL}{$i} = $split[$i];
      if( $i == 0 && $split[$i] eq '-' ){ $DATA->{"ROT"}{$gns}{$key}{$NULL}{$i} = 0.0; } # null value!
    }
  }      

  if( $line =~ m/^ ($gnss)(ROT) ($date) \s*($real) \s*(.+)$/ )
  {
    my( $key, $gns, $col, $dat, $cnt, $val ) = ("$1$2", $1, $2, $3, $4, $5);
    my( @split ) = split '\s+', $val;  $NSAT = scalar @split if $NSAT < 0;
    for(my $i=1; $i<=$NSAT; $i++){ $DATA->{"ROT"}{$gns}{$key}{$dat}{$i} = $split[$i-1]; }
  }      
  return 0;
}


1;
__END__
