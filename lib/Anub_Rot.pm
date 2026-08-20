#!/usr/bin/perl
# -----------------------------------------------------------------------------
# (c) 2025 Geodetic Observatory Pecny, http://www.pecny.cz (gnss@pecny.cz)
#     Research Institute of Geodesy, Topography and Cartography
#     Ondrejov 244, 251 65, Czech Republic
#
#  Purpose: script for plotting Anubis QC images
#
#  2025-08-08 /JD: created
#
# -----------------------------------------------------------------------------
package Anub_Rot;

use Exporter;
use File::Basename;
use lib dirname (__FILE__);
use Chart::Gnuplot;                              # DEBIAN: libchart-gnuplot-perl
use Gps_Date;
use Anub_Xtr;
use Anub_Plt;
use strict;
require Chart::Gnuplot;

@Anub_Rot::ISA    = qw( Exporter );
@Anub_Rot::EXPORT = qw( plot_rot_obs
                        plot_rot_sat
                      );

# PLOT ROT index
# -------------
sub plot_rot_obs {
  my( $file, $DATA, $opt ) = @_;

  if( ! exists $DATA->{"ROT"} ){ printf " No ROT data found ! skipped. \n"; return -1; }
  my $img = _img_file( $file, "_rot_obs" );

  my @LABEL = ();
  my @data = ();
  my $idx = 1;
  my $i = 1;
  foreach my $gnss ( reverse sort keys %{$DATA->{"ROT"}} ){
   my @PAIRS = ();
   foreach my $key ( sort keys %{$DATA->{"ROT"}{$gnss}} ){
       
     push( @LABEL, "\'$key\' $idx" );
     push( @PAIRS, [ $idx, $DATA->{"ROT"}{$gnss}{$key}{$NULL}{"0"} ] );
     $idx++;
   }
   $data[$i-1] = Chart::Gnuplot::DataSet->new(
        points => \@PAIRS,
         color => $gnscol{$gnss},
         style => "boxes", width => 4, linetype => 'solid',
          fill => { density => 0.5, border => 'on', }, 
   );
   $i++;
  }

  if( scalar @data == 0 ){ printf STDERR " ... no data for ROT plot, skipped\n"; return; }

  my $chart = Chart::Gnuplot->new(
     output => "$img",
    bmargin => "6", lmargin => "8", rmargin => "1",
      title => { text => "$opt->{TITL} - Ionosphere index / ROTI [TECU*1e2/min]", font => "Helvetica,26", offset => "0,-0.5", },
       grid => { xlines => "off", },
      ytics => { font => "Helvetica,18", },
      xtics => { labels => \@LABEL, offset => "-4,-5", font => "Courier,22", rotate => "60", },
     ylabel => { text => "ROTI [TECU*1e2/min]", font => "Helvetica,24", offset => "1,0", },
     xrange => [ "0", "$idx" ],
     yrange => [ "0", "100"  ],
     plotbg => { color => "yellow", density => "0.08", },
   boxwidth => "0.8",
  );
  $chart->plot2d( @data );

  return 0;
}


# PLOT ROT index
# -------------
sub plot_rot_sat {
  my( $file, $DATA, $opt ) = @_;

  if( ! exists $DATA->{"ROT"} ){ printf " No ROT data found ! skipped. \n"; return -1; }
  my $img = _img_file( $file, "_rot_sat" );
    
  my %PAIRS;
  my $nFIG = 0;
  foreach my $gnss ( reverse sort keys %{$DATA->{"ROT"}} ){
   foreach my $key ( sort keys %{$DATA->{"ROT"}{$gnss}} ){
    $nFIG++;
       
    foreach my $dt ( sort keys %{$DATA->{"ROT"}{$gnss}{$key}} ){
     if( $dt eq $NULL ){ next }
	
     foreach my $i ( sort keys %{$DATA->{"ROT"}{$gnss}{$key}{$dt}} ){
      my $dat = $DATA->{"ROT"}{$gnss}{$key}{$dt}{$i};
      if( $dat eq "-" ){ next }

      my( $hr, $mi, $sc ) = $dt =~ m#\d\d\d\d-\d\d-\d\d (\d\d):(\d\d):(\d\d)#;
      my $tmp = $hr + $mi/60 + $sc/3600;
      push( @{$PAIRS{$gnss}{$key}}, [ $tmp, $i, $dat/500 ]);
     }
    }
#    push( @{$PAIRS{$gnss}{$key}}, []); // simulate empty line (empty array)
   }
  }
    
  if( scalar keys %PAIRS == 0 ){ printf STDERR " ... no data for ROT (satellite-specific) plot, skipped\n"; return; }

  my $chart = Chart::Gnuplot->new(
    rmargin => "1", lmargin => "7", bmargin => "1", tmargin => "2",
  imagesize => "1.0,2.0/$nFIG",
       grid => { linetype => "dash", xlines => "off", ylines => "on", },
      xtics => { labels => [0,2,4,6,8,10,12,14,16,18,20,22,24],  font => "$fonts{$EXT}[1]", offset => "0,0.5" },
      ytics => { labels => [0,3,6,9,12,15,18,21,24,27,30,33,36], font => "$fonts{$EXT}[1]", offset => "0,0" },
     ylabel => { text => "Satellites", font => "$fonts{$EXT}[2]", offset => "1,0", },
     xrange => [ "0", "24" ],
     yrange => [ "0", "36" ],
     plotbg => { color => "yellow", density => "0.08", },
  );
  my($i, $idx ) = (1, 1);
  my $dataSet;
  my @charts = ();
  for my $gnss ( qw( GPS GLO GAL BDS ) ){
   for my $key ( reverse keys %{$PAIRS{$gnss}} ){

    $charts[$i-1][0] = $chart->copy();
    $charts[$i-1][0]->set( title => { text => "$opt->{TITL} - $key - Ionosphere index ROT [TECU*1e2/min]",
				      font => "$fonts{$EXT}[3]", offset => "0,-0.5", } );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{"$gnss"}{"$key"}},
      style => "circles",
      color => $gnscol{$gnss},
       width => "1",
       fill => { density => 0.45, border => 'on', },
    ); 
    $charts[$i-1][0]->add2d( $dataSet );

    $i++;
   }
   $idx++;
  }

  my $multiChart = Chart::Gnuplot->new(
          size => "1.0,2.0*$nFIG",
     imagesize => "1.0,2.0*$nFIG",
       output => "$img",
#        title => "$opt->{TITL} - ROT ionosphere index", # SMALL !
  );
  $multiChart->multiplot( \@charts );

  return 0;
}

1;
__END__
