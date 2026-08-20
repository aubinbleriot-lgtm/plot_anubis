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
package Anub_Sum;

use Exporter;
use File::Basename;
use lib dirname (__FILE__);
use Chart::Gnuplot;                              # DEBIAN: libchart-gnuplot-perl
use Gps_Date;
use Anub_Xtr;
use Anub_Plt;
use strict;
require Chart::Gnuplot;

@Anub_Sum::ISA    = qw( Exporter );
@Anub_Sum::EXPORT = qw( plot_sum_all
                        plot_sum_obs
                      );

# PLOT SUMMARY
# ------------
sub plot_sum_all {
  my( $file, $DATA, $opt ) = @_;    

  if( ! exists $DATA->{"SUM1"} ){ return -1; }
  my $img = _img_file( $file, "_sum_all" );

  my @LABEL  = ();
  my @LABEL2 = ();
  my @charts = ();
  my $dataSet;
  my $nFIG = 0;
  my $nGNS = 1 + 6; # $DATA->{"TOT"}{"nGNSS"};
  my $iGNS = 1;
# my $max = 0;
  my $mxE = 100;   # [%]
  my $mxX = 10000; # count

  foreach my $gnss ( reverse sort keys %{$DATA->{"SUM1"}} ){
    my $tmp = $DATA->{"SUM1"}{$gnss}{"EPO"}{"ExpEpo"};
#    if( $tmp > $max ){ $max = $tmp }
    push( @LABEL, "\'$gnss\' $iGNS" );
    push( @LABEL, "\'$gnss\' $iGNS+$nGNS+0" );
    $iGNS++;
  }

  $charts[0][0] = Chart::Gnuplot->new(
     lmargin => "6", rmargin => "2", bmargin => "1", tmargin => "1.5",
        grid => { linetype => "dot", width => "0.1", xlines => "on", ylines => "off", },
      xlabel => { text => "", font => "Helvetica,15", offset => "0,0", },
       xtics => { font => "Helvetica,10", offset => "0,0.5", length=>0 },
      xrange => [ 0, $mxE ],
      yrange => [ 0, $nGNS*2+1 ],
      plotbg => { color => "yellow", density => "0.08", },
       ytics => { labels => \@LABEL, offset => "0,0", font => "Courier,8", rotate => "0", length=>0 },
  ); 
  $nFIG++;
  $charts[$nFIG][0] = $charts[0][0]->copy(); 
  $charts[$nFIG][0]->set( xrange => [ 0, $mxX ] );
#  $charts[$nFIG][0]->set( xrange => [ 0.1, $mxX ] );
#  $charts[$nFIG][0]->set( logscale=>'x' );
    
  $nFIG++;
  $charts[$nFIG][0] = $charts[0][0]->copy(); 
  $charts[$nFIG][0]->set( xrange => [ 0, $mxX ] );
#  $charts[$nFIG][0]->set( xrange => [ 0.1, $mxX ] );
#  $charts[$nFIG][0]->set( logscale=>'x' );

  $nFIG++;
  $charts[$nFIG][0] = $charts[0][0]->copy(); 
  $charts[$nFIG][0]->set( xrange => [ 0, $nGNS * ($iGNS+1) ],
                          yrange => [ 0, 100 ],
                            grid => { linetype => "dot", width => "0.1", xlines => "off", ylines => "on" },
                           ytics => { labels => [0,10,20,30,40,50,60,70,80,90,100],  font => "Helvetica,8", length=>0 },
                          ylabel => { text => "multipath & noise\\nmoving RMS [cm]", font => "Helvetica,10", offset => "3.5,0" },
                   #      legend => { position => "right below", height => 0.8, width => 2, }, # border => "on", },
                          legend => { position => "graph 0.99,graph 1.05 horizontal", height => 1, width => 1,
			                sample => {length=>1, position=>"left",spacing=>1}, },
                        boxwidth => "0.8",
                         bmargin => "2",
                        );
  $nFIG++;

  my $TotEpo = $DATA->{"TOT"}{"Hours"}*3600.0 / $DATA->{"TOT"}{"Sample"};
  # FILL DATA
  $iGNS = 1;
  foreach my $gnss ( reverse sort keys %{$DATA->{"SUM1"}} ){

    # === Chart 1 ===      
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"EPO"}{"HavEpo"}/$TotEpo*100, $iGNS+$nGNS ]],
       style => "hbars", width => 4, linetype => 'solid',
       color => "black",
    );  
    $charts[0][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"EPO"}{"UseEpo"}/$TotEpo*100, $iGNS+$nGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => $gnscol{$gnss},
    );  
    $charts[0][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"EPO"}{"xCoEpo"}/$TotEpo*100, $iGNS-0.25 ]],
       style => "hbars", width => 3, linetype => 'solid',
       color => $gnscol{$gnss}, # "black"
    );
    $charts[0][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"EPO"}{"xPhEpo"}/$TotEpo*100, $iGNS+0.25 ]],
       style => "hbars", width => 3, linetype => 'solid',
       color => $gnscol{$gnss}, # "black"
    );  
    $charts[0][0]->add2d( $dataSet );

    # === Chart 2 ===
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"SAT"}{"xCoSat"}, $iGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => $gnscol{$gnss}, 
    );  
    $charts[1][0]->add2d( $dataSet );
      
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"SAT"}{"xPhSat"}, $iGNS+$nGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => $gnscol{$gnss}, 
    );  
    $charts[1][0]->add2d( $dataSet );

    # === Chart 3a ===
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsAll"}, $iGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => $gnscol{$gnss},
    );
    $charts[2][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsSig"} +
	           $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsSat"} +
	           $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsEpo"}, $iGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => "black",
    );  
    $charts[2][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsSat"} +
	           $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsEpo"}, $iGNS ]],
       style => "hbars", width => 4, linetype => 'solid',
       color => "white",
    );  
    $charts[2][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"XCS"}{"xcsEpo"}, $iGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => "grey",
    );  
    $charts[2][0]->add2d( $dataSet );

    # === Chart 3b ===
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"XCS"}{"numJmp"} +
 	           $DATA->{"SUM1"}{$gnss}{"XCS"}{"numSlp"}, $iGNS+$nGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => "grey",
    );  
    $charts[2][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => [[ $DATA->{"SUM1"}{$gnss}{"XCS"}{"numSlp"}, $iGNS+$nGNS ]],
       style => "hbars", width => 8, linetype => 'solid',
       color => $gnscol{$gnss},
    );
    $charts[2][0]->add2d( $dataSet );

    # === Chart 4 ===
    my $i = 0;
    my @points = ();
    foreach my $mp ( sort keys %{$DATA->{"SUM1"}{$gnss}{"MPT"}} ){
      my $value = $DATA->{"SUM1"}{$gnss}{"MPT"}{"$mp"};

                    push( @LABEL2, "\'$mp\' 1+($iGNS-1)*9 + $i" );
      if( $value ne "-" ){ push( @points, [ 1+($iGNS-1)*9 + $i,  $value ]) }
      else{                push( @points, [ 1+($iGNS-1)*9 + $i,    0.0  ]) } # for auto boxes width!
      $i++;
    }
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@points,
       style => "boxes", width => "2", linetype => "solid", title => "$gnss",
       color => $gnscol{$gnss}, fill => { density => 0.35, border => 'on', },
    );
      
    $charts[3][0]->add2d( $dataSet );
    $charts[3][0]->set( xtics => { labels => \@LABEL2, offset => "-1,-1", 
				     font => "Courier,12", rotate => "60", length=>0}, );

    $iGNS++;
  }

  # modify labels & titles
#  $charts[0][0]->arrow( from => "second $max, graph 0", head  => { size => 1, },
#                          to => "second $max, graph 1", width => 4 );
#  $charts[0][0]->label( text => "Observed",           font => "Helvetica,10", position => "graph 0.01,first 1+$iGNS+$nGNS" );
#  $charts[0][0]->label( text => "Usable",             font => "Helvetica,10", position => "graph 0.01,first 0+$iGNS" );
#  $charts[0][0]->label( text => "Black:Ph/Co (excl)", font => "Helvetica,10", position => "graph 0.10,first 0+$iGNS" );
  $charts[0][0]->label( text => "Have\\nobserv",  rotate=>"90",font => "Helvetica,10", position => "screen 0.01,first -3+$iGNS+$nGNS center" );
  $charts[0][0]->label( text => "Excl\\ncod/pha", rotate=>"90",font => "Helvetica,10", position => "screen 0.01,first -3+$iGNS center" );
#  $charts[0][0]->label( text => "phase / code\\nexcluded (black)",
#                        rotate=>"90",font => "Arial,9", position => "graph 0.97,first 1+$iGNS center" );
  $charts[0][0]->set(  title => { text => "$opt->{TITL} - Epochs [%]: all/usable [black/color] and excluded code/phase epochs [below]",
	                          font => "Helvetica,14", offset => "0,-0.8", }, );
    
#  $charts[1][0]->label( text => "Phase",             font => "Helvetica,10", position => "graph 0.01,first 1+$iGNS+$nGNS" );
#  $charts[1][0]->label( text => "Code",              font => "Helvetica,10", position => "graph 0.01,first 0+$iGNS" );
  $charts[1][0]->label( text => "Phase\\n(# obs)", rotate=>"90",font => "Helvetica,10", position => "screen 0.01,first -3+$iGNS+$nGNS center" );
  $charts[1][0]->label( text => "Code\\n(# obs)",  rotate=>"90",font => "Helvetica,10", position => "screen 0.01,first -3+$iGNS center" );
  $charts[1][0]->set(  title => { text => "$opt->{TITL} - Number of satellite observations excluded with single-frequency only [code/phase]",
	                          font => "Helvetica,14", offset => "0, -0.8", }, );

#  $charts[2][0]->label( text => "NOTE: all interruptions/cs are displayed with original color for indivudual GNSS",
#                        font => "Helvetica,10", position => "graph 0.98,first 0+$iGNS+$nGNS right" );
#  $charts[2][0]->label( text => "Interruptions due to: cycle-slip (black), all (GNSS color)",
#                        font => "Helvetica,10", position => "graph 0.01,first 0+$iGNS+$nGNS" );
#  $charts[2][0]->label( text => "Interruptions due to: epoch lost (grey), satellite lost (white), signal lost (black)", 
#                        font => "Helvetica,10", position => "graph 0.01,first 0+$iGNS" );
  $charts[2][0]->label( text => "cycle slips\\nclk jumps", rotate=>"90",
                        font => "Helvetica,10", position => "screen 0.01,first -3+$iGNS+$nGNS center" );
  $charts[2][0]->label( text => "signal\\nlosts", rotate=>"90",
                        font => "Helvetica,10", position => "screen 0.01,first -3+$iGNS center" );
#  $charts[2][0]->label( text => "Epoch (grey), Satellite (white), Signal (black)", 
#                        font => "Helvetica,10", position => "graph 0.98,first 0+$iGNS right" );
    
  $charts[2][0]->set(  title => { text => "$opt->{TITL} - Phase cycle slips/interruptions due to epoch [grey], satellite [white], signal [black]",
	                          font => "Helvetica,14", offset => "0,-0.8", }, );
    
  $charts[3][0]->set(  title => { text => "$opt->{TITL} - Code multipath at selected bands",
	                          font => "Helvetica,14", offset => "0,-0.8", },
                    );

  my $multiChart = Chart::Gnuplot->new(
#    imagesize => "0.75,$nFIG*1.8",
#    imagesize => "0.6,$nFIG*1.2",
#         size => "0.6,$nFIG*1.2",
       output => "$img",
  );
  $multiChart->multiplot( \@charts );

  return 0;
}


# PLOT SUMMARY
# ------------
sub plot_sum_obs {
  my( $file, $DATA, $opt ) = @_;    

  if( ! exists $DATA->{"SUM2"} ){ return -1; }
  my $img = _img_file( $file, "_sum_obs" );

  my @dtsat = ();
  my @dtepo = ();
  my @charts = ();
  my $dataSet;
  my $nFIG = 0;

  $charts[$nFIG][0] = Chart::Gnuplot->new(
     bmargin => "3", lmargin => "6", rmargin => "1", tmargin => "1.5",
      legend => { position => "graph 1.0, graph -0.25", height => 0, width => 1, order => "horizontal reverse",
	            sample => { position => "left", length=>2 ,spacing=>1 }, },
        grid => { linetype => "dot", xlines => "off", ylines => "on", },
       ytics => { font => "Helvetica,12", length=>0},
#      ylabel => { text => "# satellites", font => "Helvetica,14", offset => "1.5,0", },
#      yrange => [ "0", "35" ],
    boxwidth => "0.75",
      plotbg => { color => "yellow", density => "0.08", },
  );
    
  $charts[$nFIG][0]->set( title => { text => "$opt->{TITL} - Number of observed satellites per signals",
				     font => "Helvetica,16", offset => "0,-0.8", },
                                   yrange => ["0", "35"],
                                   ylabel => { text => "# satellites", font => "Helvetica,14", offset => "1.5,0", }, );
  $nFIG++;
  $charts[$nFIG][0] = $charts[0][0]->copy(); 
  $charts[$nFIG][0]->set( title => { text => "$opt->{TITL} - Observation availability at horizon [colours] vs. user elevation mask [black]",
				     font => "Helvetica,16", offset => "0,-0.8", },
                                   yrange => ["0", "100"],
                                   ylabel => { text => "% observations", font => "Helvetica,14", offset => "2.5,0", }, );
  $nFIG++;
  $charts[$nFIG][0] = $charts[0][0]->copy();
  $charts[$nFIG][0]->set( title => { text => "$opt->{TITL} - Distribution of observations w.r.t. elevation angle",
				     font => "Helvetica,16", offset => "0,-0.8", }, 
                                   yrange => ["0", "100"],
                                   ylabel => { text => "% observations", font => "Helvetica,14", offset => "2.5,0", }, );
  $nFIG++;

  my @LABEL  = ();
  my @LABEL2 = ();
  my %PAIRS;
  my %ADATA;
  my %KEYS;
  my($i, $idx, $igns) = (1, 1, 1);

  foreach my $gnss ( reverse sort keys %{$DATA->{"SUM2"}} ){
    foreach my $key ( sort keys %{$DATA->{"SUM2"}{$gnss}} ){

      push( @LABEL,  "\'$key\' $idx" );
      push( @{$PAIRS{$gnss}{"nSatel"}}, [ $idx, $DATA->{"SUM2"}{$gnss}{$key}{"nSatel"} ] );
      push( @{$PAIRS{$gnss}{"pctObs"}}, [ $idx, $DATA->{"SUM2"}{$gnss}{$key}{"pctObs"} ] );
      push( @{$PAIRS{$gnss}{"norObs"}}, [ $idx, $DATA->{"SUM2"}{$gnss}{$key}{"norObs"} ] );
      push( @{$PAIRS{$gnss}{"pctCut"}}, [ $idx, $DATA->{"SUM2"}{$gnss}{$key}{"pctCut"} ] );
      push( @{$PAIRS{$gnss}{"norCut"}}, [ $idx, $DATA->{"SUM2"}{$gnss}{$key}{"norCut"} ] );

      if( ! exists $KEYS{$gnss} and substr($key,0,1) eq "L" ){ $KEYS{$gnss} = $key; } # PHASE ONLY
      if( ! exists $KEYS{$gnss}                             ){ $KEYS{$gnss} = $key; } # ANY OTHER
      $idx++;
    }
      
    # labels for Elev histograms (3rd chart)
    my $total = scalar keys %{$DATA->{SUM0}{GNS}{ELE}};
    my $count = 0;
    foreach my $i ( sort {$a <=> $b} keys %{$DATA->{SUM0}{GNS}{ELE}} ){
      my $keyE = $KEYS{$gnss};
      my $idxE = $igns + ($igns-1)*$total + $count;
      my $keyX = $DATA->{SUM0}{GNS}{ELE}{$i};
      my $xxx = $keyX;
	 $xxx =~ s/[eE]le//g;
	 $xxx =~ s/wo\//xEle/g;

      my $val = 0.0;
      if( $DATA->{"SUM2"}{$gnss}{$keyE}{"$i"} ne "-" ){
        $val = $DATA->{"SUM2"}{$gnss}{$keyE}{"$i"} / $DATA->{"SUM0"}{$gnss}{"OBS"}{"maxObs"}*100;
      }
      push( @LABEL2, "\'$xxx\' $idxE" );
      push( @{$PAIRS{$gnss}{"nElev"}}, [ $idxE, $val ] );
      $count++;
    }
    $igns++;

    # Chart 1
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{$gnss}{"nSatel"}},
       style => "boxes", width => "2", linetype => 'solid', title => "$gnss",
       color => $gnscol{$gnss}, fill => { density => 0.35, border => 'off', },
    );  
    $charts[0][0]->add2d( $dataSet );
    $charts[0][0]->set( xtics => { labels => \@LABEL, offset => "0,-1.0", font => "Courier,10", rotate => "90",length=>0} );

    # Chart 2
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{$gnss}{"pctCut"}},
       style => "boxes", width => "2", linetype => 'solid',
       color => "black", fill => { density => 0.85, border => 'off', },
    );
    $charts[1][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{$gnss}{"pctObs"}},
       style => "boxes", width => "2", linetype => 'solid',
       color => $gnscol{$gnss}, fill => { density => 0.15, border => 'off', },
    );  
    $charts[1][0]->add2d( $dataSet );

    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{$gnss}{"norObs"}},
       style => "boxes", width => "2", linetype => 'solid', title => "$gnss",
       color => $gnscol{$gnss}, fill => { density => 0.75, border => 'off', },
    );      
    $charts[1][0]->add2d( $dataSet );
    $charts[1][0]->set( xtics => { labels => \@LABEL, offset => "0,-1.0", font => "Courier,10", rotate => "90", length=>0 } );

    # Chart 3
    $dataSet = Chart::Gnuplot::DataSet->new(
      points => \@{$PAIRS{$gnss}{"nElev"}},
       style => "boxes", width => "2", linetype => 'solid',
       color => $gnscol{$gnss}, fill => { density => 0.75, border => 'off', },
    );  
    $charts[2][0]->add2d( $dataSet );
    $charts[2][0]->set( xtics => { labels => \@LABEL2, offset => "0,-1.5", font => "Ariel,10", rotate => "90", length=>0 } );
  }

  my $multiChart = Chart::Gnuplot->new(
#    imagesize => "0.75,$nFIG*1.8",
       output => "$img",
  );
  $multiChart->multiplot( \@charts );

  return 0;
}

1;
__END__
