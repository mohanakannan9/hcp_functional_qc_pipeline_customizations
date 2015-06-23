#!/bin/csh 
set echo 
set session = $argv[1]
set wrkdir = $argv[2]
set outdir = $argv[3]
set scanid = $argv[4]

set title = "$session SCAN $scanid"

	foreach fname (`ls $wrkdir/*_FourierSlopeStatistics_4_MeanStd.txt`)
		set filename = `basename $fname .txt`
		tail -n +2 $fname |  cut -d" " -f2 > $outdir/${filename}_stripped.dat
		gnuplot -persist << PLOT
		set terminal gif small size 640,480 \\
				       xffffff x000000 x404040 \\
				       xff0000 xffa500 x66cdaa xcdb5cd \\
				       xadd8e6 x0000ff xdda0dd x9500d3    # defaults
		set key inside left top vertical Right noreverse enhanced box linetype -1 
		set xlabel "Volume"
		set ylabel "Avg Slope"
		set output '$outdir/${filename}_FourierStatistics.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:2 title "${title}: Volume vs Avg Slope"  with lines


		set terminal gif small size 300,300 \\
				       xffffff x000000 x404040 \\
				       xff0000 xffa500 x66cdaa xcdb5cd \\
				       xadd8e6 x0000ff xdda0dd x9500d3    # defaults
		set output '$outdir/${filename}_FourierStatistics_thumb.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:2 title "${title}: Volume vs Avg Slope"  with lines


		quit
		PLOT
		

	end


exit 0