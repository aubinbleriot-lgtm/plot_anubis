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
package Anub_Bnd;

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
@Anub_Bnd::EXPORT = qw( plot_bnd_sum
                        plot_bnd_sat
                        plot_bnd_tim
                      );


# PLOT Bands
# -------------
sub plot_bnd_sum {
  my( $file, $DATA, $opt ) = @_;    

  if( ! exists $DATA->{"BND"} ){ return -1; }
  my $img = _img_file( $file, "_bnd_sum" );

  my @charts = ();
  my $dataSet;
  my %rGNSS = reverse %GNSS;

  my $chart = Chart::Gnuplot->new(
        bmargin => "2", lmargin => "5", rmargin => "1", tmargin => "1",
           grid => { lines => "dot", xlines => "off", },
          ytics => { font => "Helvetica,10", length=>0 },
         yrange => [ "0", "5"  ],
         plotbg => { color => "yellow", density => "0.08", },
       boxwidth => "0.4",
  );
    
  my @data = ();
  my $iGNS = 0;
  foreach my $gns ( sort keys %{$DATA->{"BND"}} ){
   my @PHASE = ();
   my @RANGE = ();
   my @LABEL = ();
   foreach my $tmp ( sort keys %{$DATA->{"BND"}{$gns}{"CBN"}{$NULL}} ){

     my $sat = sprintf "%s%02i", $rGNSS{$gns}, $tmp;
     my $idx = $tmp - 1;
     push( @RANGE, [ $tmp-0.2, $DATA->{"BND"}{$gns}{"CBN"}{$NULL}{$tmp} ] );
     push( @PHASE, [ $tmp+0.2, $DATA->{"BND"}{$gns}{"LBN"}{$NULL}{$tmp} ] );
     push( @LABEL, "\'$sat\' $idx" );
   }

   $charts[$iGNS][0] = $chart->copy();
   $charts[$iGNS][0]->set( xtics => { labels => \@LABEL,  offset => "2,-1", length=>0,
					font => "Courier,10", rotate => "90", position => "left", },
                          xrange => [ "0", "$NSAT+1" ],
                          ylabel => { text => "$gns # bands", font => "Helvetica,12", offset => "1.5,0", },
   );

  if( scalar @data == 0 ){ printf STDERR " ... no data for band plot, skipped\n"; return; }

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
          title => "$opt->{TITL} - Code/phase bands available",
  );
  $multiChart->multiplot( \@charts );

  return 0;
}



# PLOT Bands
# -------------
sub plot_bnd_sat {
  my( $file, $DATA, $opt ) = @_;    

  if( ! exists $DATA->{"BND"} ){ return -1; }
  my $img = _img_file( $file, "_bnd_sat" );

  my $nGNSS = $DATA->{"TOT"}{"nGNSS"};   # = keys %{$DATA->{"BND"}};
  my( $width, $height ) = ( 1.0, 1.0/$nGNSS );
    ( $width, $height ) = ( 0.5, 2.0/($nGNSS+$nGNSS%2)) if $nGNSS  > 1;

  my( $imgwidth, $imgheight ) = ( 0.4, 0.2*(int($nGNSS/2)+$nGNSS%2) );
    ( $imgwidth, $imgheight ) = ( 0.3, 0.2 ) if $nGNSS == 1;

  my @charts = ();
  my $dataSet;
#  my %rGNSS = reverse %GNSS;
  my $chart = Chart::Gnuplot->new(
      size => "$width,$height",
        bmargin => "1.5", lmargin => "4", rmargin => "1", tmargin => "2",
    #    bmargin => "1", lmargin => "5", rmargin => "1", tmargin => "2",
           grid => { lines => "dot", xlines => "off", width => 0},
       boxwidth => "0.35",
         xrange => [ "-0.1", "24" ],
         yrange => [ "0", "15" ],
         plotbg => { color => "yellow", density => "0.08", },
          xtics => { labels => [0,2,4,6,8,10,12,14,16,18,20,22,24],
	             offset => "0,0.5", font => "Helvetica,10", length=>0, },
          ytics => { labels => [0,2,4,6,8,10,12,14,16,18],
	             offset => "0,0", font => "Helvetica,10", length=>0, },
  );
    
  my @data = ();
  my $iGNS = 0;
  foreach my $gns ( sort keys %{$DATA->{"BND"}} ){
    my @PHASE = ();
    my @SINGL = ();
    my @EPOCH = (); push( @EPOCH, [-999,-999] ); 
    my @NULL  = (); push( @NULL,  [-999,-999] );
    # single-freq satellites (all epochs)
    foreach my $dt ( sort keys %{$DATA->{"BND"}{$gns}{"XBN"}} ){
      my( $hr, $mi, $sc ) = $dt =~ m#\d\d\d\d-\d\d-\d\d (\d\d):(\d\d):(\d\d)#;
      $hr += $mi/60 + $sc/3600;
      push( @EPOCH, [ $hr, $DATA->{"BND"}{$gns}{"XBN"}{$dt}{"0"} ] );
    }
      
    # dual/single frequency satellites (sampling epochs)
    foreach my $dt ( sort keys %{$DATA->{"BND"}{$gns}{"CBN"}} ){
      if( $dt eq $NULL ){ next }
	
      my( $hr, $mi, $sc ) = $dt =~ m#\d\d\d\d-\d\d-\d\d (\d\d):(\d\d):(\d\d)#;
      $hr += $mi/60 + $sc/3600;
      my $count = 0;
      my $singl = 0;
      foreach my $tmp ( sort keys %{$DATA->{"BND"}{$gns}{"CBN"}{$dt}} ){
	 if( $DATA->{"BND"}{$gns}{"CBN"}{$dt}{$tmp}  > 0 ){ $count++ }   # all data
	 if( $DATA->{"BND"}{$gns}{"CBN"}{$dt}{$tmp} == 1 ){ $singl++ }   # single freq
      }
     push( @PHASE, [ $hr, $count ] );
     push( @SINGL, [ $hr, $singl ] );
   }
   my( $odd, $idx ) = (0, $iGNS);
   if( $nGNSS > 1 ){ $odd = $iGNS % 2; $idx = int($iGNS / 2); }

   if( $odd == 0 ){
     $dataSet = Chart::Gnuplot::DataSet->new( points => \@NULL );
     $charts[$idx][0] = $chart->copy();
     if( $nGNSS > 1 ){
       $charts[$idx][1] = $chart->copy();
       $charts[$idx][1]->add2d( $dataSet );
     }
   }

   $charts[$idx][$odd]->set( ylabel => { text => "$gns (# satellites)", font => "Helvetica,12", offset => "2.5,0", }, );
   $charts[$idx][$odd]->set( xlabel => { text => "time",                font => "Helvetica,12", offset => "0,1.2", }, );
      
   $dataSet = Chart::Gnuplot::DataSet->new(
     points => \@PHASE,
      color => $gnscol{$gns},
      style => "boxes", width => 1, linetype => 'solid',
       fill => { density => 0.4, border => 'off', },
   );
   $charts[$idx][$odd]->add2d( $dataSet );

   $dataSet = Chart::Gnuplot::DataSet->new(
     points => \@EPOCH,
      color => "grey", # $gnscol{$gns},
      style => "impulses", width => 6, linetype => 'solid',
#      style => "boxes", width => 1, linetype => 'solid',
#       fill => { density => 0.5, border => 'on', },
  );
   $charts[$idx][$odd]->add2d( $dataSet );
      
   $dataSet = Chart::Gnuplot::DataSet->new(
     points => \@SINGL,
      color => "black",
      style => "boxes", width => 1, linetype => 'solid',
       fill => { density => 0.8, border => 'on', },
   );
   $charts[$idx][$odd]->add2d( $dataSet );

   $iGNS++;
  };

  my $multiChart = Chart::Gnuplot->new(
       output => "$img",
    imagesize => "$imgwidth,$imgheight",
        title => "$opt->{TITL} - satells and bands: multi/single [colour/black]",
      bmargin => "5", lmargin => "5", rmargin => "1", tmargin => "3",
  );
  $multiChart->multiplot( \@charts );

  return 0;
}


# PLOT Bands
# -------------
sub plot_bnd_tim {
  my( $file, $DATA, $opt ) = @_;    

  if( ! exists $DATA->{"BND"} ){ return -1; }
  my $img = _img_file( $file, "_bnd_tim" );

  my @charts = ();
  my $dataSet;
#  my %rGNSS = reverse %GNSS;

  my $chart = Chart::Gnuplot->new(
      size => "1.0,0.22",
        bmargin => "1", lmargin => "5", rmargin => "1", tmargin => "1",
           grid => { lines => "dot", xlines => "off", width => 0},
         xrange => [ "-0.1", "24" ],
         yrange => [ "0", "36" ],
         plotbg => { color => "yellow", density => "0.08", },
          xtics => { labels => [0,2,4,6,8,10,12,14,16,18,20,22,24], 
	             offset => "0,0.5", font => "Helvetica,8", length=>0, },
          ytics => { labels => [0,4,8,12,16,20,24,28,32,36],
	             offset => "0,0", font => "Helvetica,8", length=>0, },
  );
    
  my @data = ();
  my $iGNS = 0;
  foreach my $gns ( sort keys %{$DATA->{"BND"}} ){
   my @PHASE = ();
   my @RANGE = ();
#   my @LABEL = ();
#   foreach my $tmp ( sort keys %{$DATA->{"BND"}{$gns}{"CBN"}{$NULL}} ){
    foreach my $dt ( sort keys %{$DATA->{"BND"}{$gns}{"CBN"}} ){
      if( $dt eq $NULL ){ next }
      foreach my $tmp ( sort keys %{$DATA->{"BND"}{$gns}{"CBN"}{$dt}} ){

        my( $hr, $mi, $sc ) = $dt =~ m#\d\d\d\d-\d\d-\d\d (\d\d):(\d\d):(\d\d)#;
        $hr += $mi/60 + $sc/3600;

        push( @RANGE, [ $hr, $tmp,  $DATA->{"BND"}{$gns}{"CBN"}{$dt}{$tmp}/50  ] );
        push( @PHASE, [ $hr, $tmp, ($DATA->{"BND"}{$gns}{"LBN"}{$dt}{$tmp}/50) ] );
        printf "%5.2f %5.2f %5.2f\n",
	          $DATA->{"BND"}{$gns}{"LBN"}{$dt}{$tmp},
  	          $DATA->{"BND"}{$gns}{"LBN"}{$dt}{$tmp}/25,
                  $DATA->{"BND"}{$gns}{"LBN"}{$dt}{$tmp}/25 - 1.5;
     }
   }
   $charts[$iGNS][0] = $chart->copy();
   $charts[$iGNS][0]->set( ylabel => { text => "$gns satellites", font => "Helvetica,12", offset => "1.8,0", }, );
      
#   $dataSet = Chart::Gnuplot::DataSet->new(
#     points => \@RANGE,
#      color => $gnscol{$gns},
#      style => "lines", width => 1, linetype => 'solid',
#   );
#   $charts[$iGNS][0]->add2d( $dataSet );
      
   $dataSet = Chart::Gnuplot::DataSet->new(
     points => \@PHASE,
      color => $gnscol{$gns},       
#      style => "points", width => 1, pointtype => "5", # linetype => 'solid',
      style => "circles", width => 1, # pointtype => "5", linetype => 'solid',
       fill => { density => 0.8, border => 'on', },
   );
   $charts[$iGNS][0]->add2d( $dataSet );

   $iGNS++;
  };

  my $multiChart = Chart::Gnuplot->new(
#       size => "1*$iGNS,1",
#    imagesize => "0.5*$iGNS,1",
#    imagesize => "0.5,1",
       output => "$img",
#      bmargin => "3", lmargin => "5", rmargin => "1", tmargin => "5",
        title => "$opt->{TITL} - code/phase bands available",
#      bmargin => "3", lmargin => "5", rmargin => "1", tmargin => "5",

  );
  $multiChart->multiplot( \@charts );

  return 0;
}


1;
__END__



# PLOT Bands
# -------------
sub plot_bnd_sky {
  my( $file, $DATA, $opt ) = @_;
  if( ! exists $DATA->{"BND"} ){ return -1; }
  my $img = _img_file( $file, "_bnd_sky" );
    
  my %PAIRS;

  my $nFIG = 0;
  foreach my $gns ( reverse sort keys %{$DATA->{"BND"}} ){
   foreach my $key ( sort keys %{$DATA->{"BND"}{$gns}} ){
    $nFIG++;
       
    foreach my $dt ( sort keys %{$DATA->{"BND"}{$gns}{$key}} ){
     if( $dt eq $NULL ){ next }
	
     foreach my $i ( sort keys %{$DATA->{"BND"}{$gns}{$key}{$dt}} ){
      my $dat = $DATA->{"BND"}{$gns}{$key}{$dt}{$i};
      if( $dat eq "-" ){ next }

      my( $hr, $mi, $sc ) = $dt =~ m#\d\d\d\d-\d\d-\d\d (\d\d):(\d\d):(\d\d)#;
      my $tmp = $hr + $mi/60 + $sc/3600;
      push( @{$PAIRS{$gns}{$key}}, [ $tmp, $i, $dat/250 ]);
     }
    }
   }
  }

  if( scalar keys %PAIRS == 0 ){ printf STDERR " ... no data for band (satellite-specific) plot, skipped\n"; return; }
    
  my($i, $idx ) = (1, 1);
  my $dataSet;
  my @charts = ();
  for my $gns ( qw( GPS GLO GAL BDS ) ){
   for my $key ( reverse keys %{$PAIRS{$gns}} ){

    $charts[$i-1][0] = Chart::Gnuplot->new(
     rmargin => "3", lmargin => "7",
       title => { text => "$opt->{TITL}  $key - Code multipath", font => "Helvetica,28", offset => "0,-0.5", },
        grid => { linetype => "dash", xlines => "off", ylines => "on", },
       xtics => { labels => [0,2,4,6,8,10,12,14,16,18,20,22,24], },
       ytics => { labels => [0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34], },
#     y2tics => { labels => [0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34], },
      ylabel => { text => "Satellites", font => "Helvetica,24", offset => "1,0", },
      xrange => [ "0", "24" ],
      yrange => [ "0", "36" ],
    );
    if( $i == $nFIG ){
      $charts[$i-1][0]->set( xlabel => { text => "date", font => "Helvetica,24", offset => "1,0", } );
    }

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{"$gns"}{"$key"}}, 
       style => "circles",
       color => $gnscol{$gns},
       width => "1",
        fill => { density => 0.45, border => 'on', color => 'red', },
    );  
    $charts[$i-1][0]->add2d( $dataSet );

    $i++;
   }
   $idx++;
  }

  my $multiChart = Chart::Gnuplot->new(
#    imagesize => "0.75,$nFIG*2.4",
       output => "$img", 
  );
  $multiChart->multiplot( \@charts );

  return 0;
}
