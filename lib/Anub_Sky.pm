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
package Anub_Sky;

use Exporter;
use File::Basename;
use lib dirname (__FILE__);
use Chart::Gnuplot;                              # DEBIAN: libchart-gnuplot-perl
use Gps_Date;
use Anub_Xtr;
use Anub_Plt;
use strict;
require Chart::Gnuplot;

@Anub_Sky::ISA    = qw( Exporter );
@Anub_Sky::EXPORT = qw( plot_sky_map
                      );

# PLOT Bands
# -------------
sub plot_sky_map {
  my( $file, $DATA, $opt ) = @_;
    
  if( ! exists $DATA->{"SKY"} ){ return -1; }
  my $img = _img_file( $file, "_sky_map" );
    
  my @charts = ();
  my @NULL  = (); push( @NULL,  [-999,-999] );
  my $dataSet;
  my %PAIRS;
  my %SINGL;
  my %rGNSS = reverse %GNSS;

  my $nGNSS = $DATA->{"TOT"}{"nGNSS"};   # = keys %{$DATA->{"BND"}};
  my( $width, $height ) = ( 1.0, 1.0/$nGNSS );
    ( $width, $height ) = ( 0.5, 2.0/($nGNSS+$nGNSS%2)) if $nGNSS  > 1;

  my( $imgwidth, $imgheight ) = ( 0.4, 0.2*(int($nGNSS/2)+$nGNSS%2) );
    ( $imgwidth, $imgheight ) = ( 0.3, 0.2 ) if $nGNSS == 1;
#  printf "$nGNSS = $width:$height   $imgwidth:$imgheight  %10.2f\n", int($nGNSS/2)+$nGNSS%2;

  my $chart = Chart::Gnuplot->new(
       size => "$width,$height",  # => 0.5, 0.33,
    bmargin => "1.5", lmargin => "4", rmargin => "1", tmargin => "2",
       grid => { lines => "dot", xlines => "on", ylines => "off", },
      ytics => { font => "Helvetica,12", length=>0, offset=>"0.5,0", labels=>[0,10,20,30,40,50,60,70,80,90], },
      xtics => { font => "Helvetica,12", length=>0, offset=>"0,0.5", labels=>[0,90,180,270,360], },
     ylabel => { font => "Helvetica,14", text => "elevation", offset => "2.5,0" },
     xlabel => { font => "Helvetica,14", text => "azimuth",   offset => "0,1.2" },
     yrange => [ "0", "95"  ],
     xrange => [ "0", "360" ],
     plotbg => { color => "yellow", density => "0.08", },
  );

  my $iGNS = 0;
  foreach my $gns ( sort keys %{$DATA->{"SKY"}} ){
    my %sold;
    my %sats;
    my %azim;
    my $iDAT = 0;
    foreach my $dt ( sort keys %{$DATA->{"SKY"}{$gns}{"ELE"}} ){       
      $iDAT++;

      foreach my $i ( sort keys %{$DATA->{"SKY"}{$gns}{"ELE"}{$dt}} ){

        my $ele =  $DATA->{"SKY"}{$gns}{"ELE"}{$dt}{$i};
        my $azi =  $DATA->{"SKY"}{$gns}{"AZI"}{$dt}{$i};

        if( ! exists $sats{$i} ){ $sats{$i} = 1; }

        if( defined $ele &&
  	    defined $azi &&
	     "-" ne $ele &&
	     "-" ne $azi    ){

            my $count = $i;
	    if( exists $azim{$i} && abs($azim{$i}-$azi) > 90 ){
		   $sats{$i} = $iDAT;
	    }else{ $azim{$i} = $azi }
            $count += 100*$sats{$i};

#           printf "$gns $i .... idat = $iDAT  azi = $azim{$i} x $azi  ele = $ele   => $count\n";

	    if( ( exists $DATA->{"BND"}{$gns}{"LBN"}{$dt}{$i} and
	                 $DATA->{"BND"}{$gns}{"LBN"}{$dt}{$i} < 2 ) or
                ( exists $DATA->{"BND"}{$gns}{"CBN"}{$dt}{$i} and
	                 $DATA->{"BND"}{$gns}{"CBN"}{$dt}{$i} < 2 )){
              push( @{$SINGL{$gns}}, [ $azi, $ele, 2.0 ] );
	    }
            push( @{$PAIRS{$gns}{ $count }}, [ $azi, $ele ]);
            $azim{$i} = $azi;
	    $sold{$i} += 1;
     	 }else{
	   $sold{$i} = 0;
	   $sats{$i} = $iDAT;
        }
      }
    }

    my( $odd, $idx ) = (0, $iGNS);
    if( $nGNSS > 1 ){ $odd = $iGNS % 2; $idx = int($iGNS / 2); }

    if( $odd == 0 ){
      $dataSet = Chart::Gnuplot::DataSet->new( points => \@NULL );
      $charts[$idx][0] = $chart->copy();
      $charts[$idx][0]->add2d( $dataSet );  # to be save
      if( $nGNSS > 1 ){
        $charts[$idx][1] = $chart->copy();
        $charts[$idx][1]->add2d( $dataSet ); # to be save
      }
    }
    
    foreach my $i ( keys %{$PAIRS{$gns}} ){

      my( $style, $ptsize ) = ( "linespoints", 0.4 );
        ( $style, $ptsize ) = ( "points",     0.25 ) if (scalar keys %{$DATA->{"SKY"}{$gns}{"ELE"}}) > 100;

      $dataSet = Chart::Gnuplot::DataSet->new(
        points => \@{$PAIRS{$gns}{$i}},
         style => "$style", pointtype => "7", linetype => "dot", pointsize => "$ptsize",
         color => $gnscol{$gns}, width => "2",
      );
      $charts[$idx][$odd]->add2d( $dataSet );
    }
      
    # plot single frequency data only
    if( exists $SINGL{$gns} and scalar @{$SINGL{$gns}} > 0 ){
     $dataSet = Chart::Gnuplot::DataSet->new(
       points => \@{$SINGL{$gns}},
        style => "circles", linetype => "solid",
        color => "black", width => "2",
        fill  => { density => 1.0, border => "off" },
      );
      $charts[$idx][$odd]->add2d( $dataSet );
    }

    $charts[$idx][$odd]->label( text => "$gns",
	                        font => "Helvetica,16",
	                    position => "graph 0.02,graph 0.9" );
    $iGNS++;
  }

  my $multiChart = Chart::Gnuplot->new(
#    imagesize => "0.75,$nFIG*2.4",
    imagesize => "$imgwidth,$imgheight",
       output => "$img",
        title => "$opt->{TITL} - Satellite sky tracks (azimuth-elevation plot)",
      bmargin => "5", lmargin => "5", rmargin => "1", tmargin => "3",
  );
    
  $multiChart->multiplot( \@charts );

  return 0;
}

1;
__END__
