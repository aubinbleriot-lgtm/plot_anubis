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
package Anub_Pos;

use Exporter;
use File::Basename;
use lib dirname (__FILE__);
use Chart::Gnuplot;                              # DEBIAN: libchart-gnuplot-perl
use Gps_Date;
use Anub_Xtr;
use Anub_Plt;
use strict;
require Chart::Gnuplot;

@Anub_Pos::ISA    = qw( Exporter );
@Anub_Pos::EXPORT = qw( plot_pos_blh
                        plot_pos_neu
                      );
my $LIMPOS = 15.0; #  7.5;
my $pi = 3.141592653589;
my $cf = 6378000*$pi/180;

# PLOT POSITION
# -------------
sub plot_pos_blh {
  my( $file, $DATA, $opt ) = @_;

  if( ! exists $DATA->{"POS"} ){ return -1; }
  my $img = _img_file( $file, "_pos_blh" );

  my @LABEL = ();
  my @data = ();
  my ($i,$idx) = (1,1);
  foreach my $gnss ( reverse sort keys %{$DATA->{"POS"}} ){

    push( @LABEL, "\'$gnss: N\' $idx" ); $idx++;
    push( @LABEL, "\'$gnss: E\' $idx" ); $idx++;
    push( @LABEL, "\'$gnss: U\' $idx" ); $idx++;

    $data[$i-1] = Chart::Gnuplot::DataSet->new(
          style => "boxes", width => "4", linetype => 'solid',
          color => $gnscol{$gnss}, title => "$gnss",
         points => [ [ $idx-3, $DATA->{"POS"}{$gnss}{"RMS"}{"B"} ],
	             [ $idx-2, $DATA->{"POS"}{$gnss}{"RMS"}{"L"} ],
	             [ $idx-1, $DATA->{"POS"}{$gnss}{"RMS"}{"H"} ] ],
           fill => { density => 0.3, border => 'off', },
    );
    $idx++;
    $i++;
  }

  if( scalar @data == 0 ){ printf STDERR " ... no data for position plot, skipped\n"; return; }

  my $chart = Chart::Gnuplot->new(
     output => "$img",
     legend => { position => "top left", height => 0.5, width => 3, border => "on", },
    bmargin => "6", lmargin => "8", rmargin => "1",
      title => { text => "$opt->{TITL} - Standard positioning", 
	         font => "Helvetica,26", offset => "0,-0.5", },
       grid => { xlines => "off", },
      ytics => { font => "Helvetica,18", },
      xtics => { labels => \@LABEL, offset => "-4,-5", font => "Courier,22", rotate => "60", },
     ylabel => { text => "RMS [m]", font => "Helvetica,24", offset => "1,0", },
     xrange => [ "0", "$idx-1" ],
     yrange => [ "0", "15" ],
   boxwidth => "0.8",
     plotbg => { color => "yellow", density => "0.08", },
  );
    
  $chart->plot2d( @data );
  return 0;
}
    

# PLOT POSITION (TIME-SERIES)
# -------------
sub plot_pos_neu {
  my( $file, $DATA, $opt ) = @_;
  my @data = ();

  if( ! exists $DATA->{"EST"} ){ return -1; }
  my $img = _img_file( $file, "_pos_neu" );

  my $iGNS = 0;
  foreach my $gns ( sort keys %{$DATA->{"EST"}} ){
    my @PAIRS = ();
    foreach my $dt ( sort keys %{$DATA->{"EST"}{$gns}{"POS"}} ){
      foreach my $i ( sort keys %{$DATA->{"EST"}{$gns}{"POS"}{$dt}} ){

        push( @PAIRS, [ ($DATA->{"EST"}{$gns}{"POS"}{$dt}{"B"} - $DATA->{"POS"}{$gns}{"EST"}{"B"})*$cf,
 	                ($DATA->{"EST"}{$gns}{"POS"}{$dt}{"L"} - $DATA->{"POS"}{$gns}{"EST"}{"L"})*$cf,
	                ($DATA->{"EST"}{$gns}{"POS"}{$dt}{"DOP"} < 10)?
	                 $DATA->{"EST"}{$gns}{"POS"}{$dt}{"DOP"}/10: 1
	              ]
            );
      }
    }      
    $data[$iGNS] = Chart::Gnuplot::DataSet->new(
       style => "circles",
      points => \@PAIRS,
       color => $gnscol{$gns}, title => "$gns", linetype => "solid",
        fill => { density => 0.2, border => 'on', },
    );
    $iGNS++;
  }

  my $chart = Chart::Gnuplot->new(
     output => "$img",    lmargin => "6",
     legend => { position => "top left", align => "right", spacing => 1, height => 0.5, width => 3, border => "on", },
      title => { text => "$opt->{TITL} - Standard positioning", font => "Helvetica,26", offset => "0,-0.5", },
     ylabel => { text => "North - South [m]", font => "Helvetica,22", offset => "1,0", },
     xlabel => { text => "West - East [m]",   font => "Helvetica,22", offset => "0,0", },
     xrange => [ "-$LIMPOS", "$LIMPOS" ],
     yrange => [ "-$LIMPOS", "$LIMPOS" ],
       grid => { xlines => "on", ylines => "on", },
     plotbg => { color => "yellow", density => "0.08", },
  );

# $chart->set( pm3d => "clip4in" ); # not work for LARGE POINTS (part of point outside plot!)
# $chart->set( clip => "one" );     # not work for LARGE POINTS (part of point outside plot!)

  $chart->plot2d( @data );
  return 0;
}

1;
__END__
