#!/usr/bin/perl
# -----------------------------------------------------------------------------
# (c) 2011 Geodetic Observatory Pecny, http://www.pecny.cz (gnss@pecny.cz)
#     Research Institute of Geodesy, Topography and Cartography
#     Ondrejov 244, 251 65, Czech Republic
#
#  Purpose: script for plotting Anubis QC images
#
#  2015-01-18 /JD: created
#
# -----------------------------------------------------------------------------
package Anub_Plt;

use Exporter;
use File::Basename;
use lib dirname (__FILE__);
use Chart::Gnuplot;                              # DEBIAN: libchart-gnuplot-perl
use Gps_Date;
use Anub_Xtr;
use strict;
require Chart::Gnuplot;

@Anub_Plt::ISA    = qw( Exporter );
@Anub_Plt::EXPORT = qw( $EXT
                        %fonts  %gnscol
                        &_img_file );

our $EXT = ".eps"; 

our %fonts = ( ".eps" => [ "Helvetica,12", "Helvetica,16", "Helvetica,20", "Helvetica,24", "Helvetica,28", "Helvetica,34" ],
               ".png" => [ "Helvetica,8",  "Helvetica,10", "Helvetica,12", "Helvetica,15", "Helvetica,18", "Helvetica,20" ]
             );

our %gnscol = ( "GPS" => "dark-turquoise",
                "GLO" => "green", 
                "GAL" => "red",
                "BDS" => "orange",
                "SBS" => "pink",           # violet
                "QZS" => "violet");  # "dark-magenta" ); # "blue", "pink", "yellow", };

my @formats = qw( .eps .png ); # not .jpg



# MODIFY IMAGE NAME
# -----------------
sub _img_file {
  my( $file, $add ) = @_;
  my( $name, $path, $ext ) = fileparse( $file, @formats );  # printf "# file = $path${name}$add$EXT $ext \n";

  if( $ext ne "" ){  $file = "$path${name}$add$ext"; $EXT = $ext; }
  else            {  $file = "$path${name}$add$EXT"; }  

  printf "# plot = $file \n";
  return $file;
}

1;
__END__
