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
package Anub_Obs;

use Exporter;
use File::Basename;
use lib dirname (__FILE__);
use Chart::Gnuplot;                              # DEBIAN: libchart-gnuplot-perl
use Gps_Date;
use Anub_Xtr;
use Anub_Plt;
use strict;
require Chart::Gnuplot;

@Anub_Bnd::ISA    = qw( Exporter );
@Anub_Bnd::EXPORT = qw( plot_obs_sat
                      );


# PLOT Observations
# -------------
sub plot_obs_sat {
  my( $file, $DATA, $opt ) = @_;    

  if( ! exists $DATA->{"OBS"} ){ return -1; }
  my $img = _img_file( $file, "_bnd_sat" );

  my @charts = ();
  my $dataSet;
  my %rGNSS = reverse %GNSS;

  my $chart = Chart::Gnuplot->new(
        bmargin => "2", lmargin => "5", rmargin => "1", tmargin => "0",
           grid => { lines => "dot", xlines => "off", },
          ytics => { font => "Helvetica,10", length=>0 },
         yrange => [ "0", "5"  ],
       boxwidth => "0.4",
  );
    
  my @data = ();
  my $iGNS = 0;
  foreach my $gns ( sort keys %{$DATA->{"OBS"}} ){
   my @PHASE = ();
   my @RANGE = ();
   my @LABEL = ();
   foreach my $tmp ( sort keys %{$DATA->{"OBS"}{$gns}{"CBN"}{$NULL}} ){

     my $sat = sprintf "%s%02i", $rGNSS{$gns}, $tmp;
     my $idx = $tmp - 1;
     push( @RANGE, [ $tmp-0.2, $DATA->{"OBS"}{$gns}{"CBN"}{$NULL}{$tmp} ] );
     push( @PHASE, [ $tmp+0.2, $DATA->{"OBS"}{$gns}{"LBN"}{$NULL}{$tmp} ] );
     push( @LABEL, "\'$sat\' $idx" );
   }
      
  if( scalar @data == 0 ){ printf STDERR " ... no data for observation (satellite-specific) plot, skipped\n"; return; }

   $charts[$iGNS][0] = $chart->copy();
   $charts[$iGNS][0]->set( xtics => { labels => \@LABEL,  offset => "2,-1", length=>0,
					font => "Courier,10", rotate => "90", position => "left", },
                          xrange => [ "0", "$NSAT+1" ],
                          ylabel => { text => "$gns # bands", font => "Helvetica,12", offset => "1.5,0", },
   );
      
   $dataSet = Chart::Gnuplot::DataSet->new(
     points => \@RANGE,
      color => $gnscol{$gns},
      style => "boxes", width => 1, linetype => 'solid',
       fill => { density => 0.4, border => 'on', },
   );
   $charts[$iGNS][0]->add2d( $dataSet );
      
   $dataSet = Chart::Gnuplot::DataSet->new(
     points => \@PHASE,
      color => $gnscol{$gns},
      style => "boxes", width => 1, linetype => 'solid',
       fill => { density => 0.8, border => 'on', },
   );
   $charts[$iGNS][0]->add2d( $dataSet );

   $iGNS++;
  }

  my $multiChart = Chart::Gnuplot->new(
#    imagesize => "0.75,$nFIG*2.4",
#         size => "0.6,$nFIG*1.2",
       output => "$img", 
        bmargin => "5", lmargin => "5", rmargin => "1", tmargin => "2",
          title => "$opt->{TITL} - Code/phase signals available",
  );
  $multiChart->multiplot( \@charts );

  return 0;
}

1;
__END__
