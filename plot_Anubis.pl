#!/usr/bin/perl -w 
#
# created: 2014-Aug-08 /JD
# lastupd: 2014-Aug-08 /JD
#
# purpose: script providing Anubis output QC plots
#
# example: ./plot_Anubis.pl --help
#          ./plot_Anubis.pl --plot --all --all  --ifile SITE.xtr  --title="SITE [YEAR:DOY]"
#          ./plot_Anubis.pl --plot --pos --pos --no-GPS --no-GLO --ifile SITE.xtr
# ----------------------------------------------------------------------

use File::Basename qw( dirname );
use lib dirname (__FILE__);
use lib dirname (__FILE__) . "/lib";
use Getopt::Long qw(:config ignore_case);
use Gps_Date;
use Anub_Xtr;
use Anub_Plt;
use Anub_Sum;
use Anub_Pos;
use Anub_Sky;
use Anub_Bnd;
use Anub_Mpt;
use Anub_Snr;
use Anub_S4c;
use Anub_Rot;
use strict;

my( %DATA );
my( $VER ) = "2.0.2";
my( %opt ) = ( 'FILE' => undef, 
               'DATA' => 0, 'DATA' => 0, 'TITL' => "",
               'VERB' => 0, 'HELP' => 0, # 'GREP' => "",
                'SUM' => 0,  'HDR' => 0,  'GAP' => 0,  'PRE' => 0,  'EST' => 0,
                'BND' => 0,  'SKY' => 0,  'OBS' => 0,  'MPT' => 0,  'SNR' => 0,  'S4C' => 0,  'ROT' => 0,
                'GPS' => 0,  'GLO' => 0,  'GAL' => 0,  'BDS' => 0,  'SBS' => 0,  'QZS' => 0,

                'REC' => 0,  'ANT' => 0,  'GNS' => 0,  'SIT' => 0, # EXTRACTIONS ONLY!

                'ALL' => 0
             );

GetOptions(   'ifile=s'  => \$opt{'FILE'},
              'egrep=s'  => \$opt{'GREP'},
              'title=s'  => \$opt{'TITL'},
              'all+'     => \$opt{'ALL'},
              'obs+'     => \$opt{'OBS'},
              'bnd+'     => \$opt{'BND'},
              'mpt+'     => \$opt{'MPT'},
              'snr+'     => \$opt{'SNR'},
              's4c+'     => \$opt{'S4C'},
              'rot+'     => \$opt{'ROT'},
              'pos+'     => \$opt{'EST'},
              'sum+'     => \$opt{'SUM'},
              'sky+'     => \$opt{'SKY'},
              'plot=s'   => \$opt{'PLOT'},
              'gnss+'    => \$opt{'GNS'},
              'site+'    => \$opt{'SIT'},
              'ant+'     => \$opt{'ANT'},
              'rec+'     => \$opt{'REC'},
              'GPS!'     => \$opt{'GPS'},
              'GLO!'     => \$opt{'GLO'},
              'GAL!'     => \$opt{'GAL'},
              'BDS!'     => \$opt{'BDS'},
              'SBS!'     => \$opt{'SBS'},
              'QZS!'     => \$opt{'QZS'},
              'verb+'    => \$opt{'VERB'},
              'help'     => \$opt{'HELP'}  ) or &Usage("");

# SET ALL IF NO SPECIAL REQUEST
if( $opt{GPS} == 0 and $opt{GLO} == 0 and $opt{GAL} == 0 and $opt{BDS} == 0 and $opt{QZS} == 0 and $opt{SBS} == 0 ){
    $opt{GPS} = $opt{GLO} = $opt{GAL} = $opt{BDS} = $opt{QZS} = $opt{SBS} = 1; }

if( $opt{'HELP'} ){ &Usage(""); }
if( ! defined $opt{'FILE'} or !  -f $opt{'FILE'} or 
    ! defined $opt{'PLOT'}  ){ &Usage("\n Error: input file not valid!"); }

printf "# InpFil : $opt{FILE}   \n" if $opt{'VERB'} > 1 and defined $opt{'FILE'};
printf "# %s\n",             '-'x60 if $opt{'VERB'} > 1;

xtr_file( $opt{"FILE"}, \%DATA, \%opt ); # EXTRACT

if( $opt{'VERB'} > 0 ){
  printf "# Anubis extractions [$VERS] for ... \n";
  printf "# fil = $DATA{'FIL'}\n";
  printf "# sit = $DATA{'SIT'}\n";
  printf "# rec = $DATA{'REC'}\n";
  printf "# ant = $DATA{'ANT'}\n";
}

# ==============
# == PLOTTING ==
# ==============

if( exists $opt{"PLOT"} ){
    
  plot_sum_all( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"SUM"} > 0 || $opt{"ALL"} > 0;
  plot_sum_obs( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"SUM"} > 1 || $opt{"ALL"} > 1;
    
  plot_pos_blh( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"EST"} > 0 || $opt{"ALL"} > 0;
  plot_pos_neu( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"EST"} > 1 || $opt{"ALL"} > 1;
    
  plot_mpt_obs( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"MPT"} > 0 || $opt{"ALL"} > 0;
  plot_mpt_sat( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"MPT"} > 1 || $opt{"ALL"} > 1;
    
  plot_snr_obs( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"SNR"} > 0 || $opt{"ALL"} > 0;
  plot_snr_sat( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"SNR"} > 1 || $opt{"ALL"} > 1;
    
  plot_s4c_obs( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"S4C"} > 0 || $opt{"ALL"} > 0;
  plot_s4c_sat( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"S4C"} > 1 || $opt{"ALL"} > 1;
    
  plot_rot_obs( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"ROT"} > 0 || $opt{"ALL"} > 0;
  plot_rot_sat( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"ROT"} > 1 || $opt{"ALL"} > 1;
    
  plot_bnd_sum( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"BND"} > 0 || $opt{"ALL"} > 0;
  plot_bnd_sat( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"BND"} > 1 || $opt{"ALL"} > 1;
# plot_bnd_tim( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"BND"} > 2 || $opt{"ALL"} > 2;
    
  plot_sky_map( $opt{"PLOT"}, \%DATA, \%opt ) if $opt{"SKY"} > 0 || $opt{"ALL"} > 0;

}

exit;

# ==============
# == PRINTING ==
# ==============

if( $opt{"DATA"} > 0 ){
    
 foreach my $id ( qw( EST MPT SNR S4C ROT BND OBS ) ){
     
   if( $opt{$id} == 0 ){ next; } # SKIP
 
   foreach my $gns ( sort keys %{$DATA{"$id"}} ){
    foreach my $key ( sort keys %{$DATA{"$id"}{$gns}} ){
  
      # remove any sub-id if exists (key:subkey)
      my $subkey  = $key; $subkey =~ s/:.*//g;

      if( $key !~ /$opt{'GREP'}/ ){ next } # FILTER OUT!
      
      printf "#%3s %4s  %17s  %9s : %3s %3s  %7s\n", "GNS", "id", "year-mm-dd hr:mm:ss", "keyword", "azi", "ele", "value";

      foreach my $dt ( sort keys %{$DATA{"$id"}{$gns}{$key}} ){  
        foreach my $i ( sort keys %{$DATA{"$id"}{$gns}{$key}{$dt}} ){
  
          if( exists $DATA{"AZI"}{$gns}{"${gns}AZI"}{$dt}{$i} and
              exists $DATA{"ELE"}{$gns}{"${gns}ELE"}{$dt}{$i}
          ){
             printf " %3s %4s  %17s  %9s : %3s %3s  %7s\n", $gns, $i, $dt, $subkey,
  	             $DATA{"AZI"}{$gns}{"${gns}AZI"}{$dt}{$i},
  	             $DATA{"ELE"}{$gns}{"${gns}ELE"}{$dt}{$i},
  	             $DATA{"$id"}{$gns}{$key}{$dt}{$i};
          }else{
              printf " %3s %4s  %17s  %9s : %3s %3s  %7s\n", $gns, $i, $dt, $subkey,
                     "999","999",$DATA{"$id"}{$gns}{$key}{$dt}{$i};
          }
        }
      }
    }
    printf "\n";
  }
 }
}

# ==================================================================================
# INTERNAL SUBROUTINES

# usage
# -----
sub Usage {  
printf "\n$0  Version: $VER \n";
printf "@_\n";
format HELP =

 Usage: plot_Anubis.pl options
      
   < --ifile       inp_file >   .. input file      
   < --title         string >   .. plot base title
   < --plot        img_name >   .. plot request (filename)
   [ --egrep         string ]   .. filtering string
   [ --bnd                  ]   .. number of bands
   [ --obs                  ]   .. observation statistics
   [ --pos                  ]   .. positioning results
   [ --mpt                  ]   .. code of multipath and noise
   [ --snr                  ]   .. phase signal-to-noise ratio
   [ --s4c                  ]   .. S4C ionospheric index
   [ --rot                  ]   .. ROT ionospheric index
   [ --sky                  ]   .. elevation/azimuth plot
   [ --sum                  ]   .. total summary
   [ --all                  ]   .. plot all figures
   [ --GNS | --no-GNS       ]   .. selected GNSS only (GNS=GPS,GLO,GAL,BDS,SBS,QZS)
   [ --rec | --ant          ]   .. rec|antenna  & stop
   [ --site                 ]   .. site name    & stop
   [ --gnss                 ]   .. gnss systems & stop
   [ --verb                 ]   .. verbosity level
   [ --help                 ]   .. this help

.

  open(HELP,">>/dev/stderr");
  write HELP;
  close(HELP);
  exit 1;
}

__END__
