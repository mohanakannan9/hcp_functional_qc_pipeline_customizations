#!/bin/csh 
set echo 
set session = $argv[1]
set wrkdir = $argv[2]
set outdir = $argv[3]
set scanid = $argv[4]

set title = "$session SCAN $scanid"

	foreach fname ( $wrkdir/*_WaveletKurtMean_4.txt )
		set filename = `basename $fname .txt`
		tail -n +2 $fname |  cut -d" " -f2 > $outdir/${filename}_stripped.dat
		gnuplot -persist <<PLOT
		set terminal gif small size 640,480 \\
				       xffffff x000000 x404040 \\
				       xff0000 xffa500 x66cdaa xcdb5cd \\
				       xadd8e6 x0000ff xdda0dd x9500d3    # defaults
		set key inside left top vertical Right noreverse enhanced box linetype -1 
		set xlabel "Volume"
		set ylabel "CH"
		set output '$outdir/${filename}_WaveletKurtosisMean_CH.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:3 title "${title}: Trace 1", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:6 title "Trace 2", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:9 title "Trace 3",  \\
		 '$wrkdir/${filename}_stripped.dat' using 1:12 title "Trace 4",\\
		 '$wrkdir/${filename}_stripped.dat' using 1:15 title "Trace 5"  with lines

		set ylabel "CV"
		set output '$outdir/${filename}_WaveletKurtosisMean_CV.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:4 title "${title}: Trace 1", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:7 title "Trace 2", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:10 title "Trace 3",  \\
		 '$wrkdir/${filename}_stripped.dat' using 1:13 title "Trace 4",\\
		 '$wrkdir/${filename}_stripped.dat' using 1:16 title "Trace 5"  with lines
		 

		set ylabel "CD"
		set output '$outdir/${filename}_WaveletKurtosisMean_CD.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:5 title "${title}: Trace 1", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:8 title "Trace 2", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:11 title "Trace 3",  \\
		 '$wrkdir/${filename}_stripped.dat' using 1:14 title "Trace 4",\\
		 '$wrkdir/${filename}_stripped.dat' using 1:17 title "Trace 5"  with lines
		 

		set terminal gif small size 300,300 \\
				       xffffff x000000 x404040 \\
				       xff0000 xffa500 x66cdaa xcdb5cd \\
				       xadd8e6 x0000ff xdda0dd x9500d3    # defaults
		set ylabel "CH"
		set output '$outdir/${filename}_WaveletKurtosisMean_CH.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:3 title "${title}: Trace 1", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:6 title "Trace 2", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:9 title "Trace 3",  \\
		 '$wrkdir/${filename}_stripped.dat' using 1:12 title "Trace 4",\\
		 '$wrkdir/${filename}_stripped.dat' using 1:15 title "Trace 5"  with lines

		set ylabel "CV"
		set output '$outdir/${filename}_WaveletKurtosisMean_CV.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:4 title "${title}: Trace 1", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:7 title "Trace 2", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:10 title "Trace 3",  \\
		 '$wrkdir/${filename}_stripped.dat' using 1:13 title "Trace 4",\\
		 '$wrkdir/${filename}_stripped.dat' using 1:16 title "Trace 5"  with lines
		 

		set ylabel "CD"
		set output '$outdir/${filename}_WaveletKurtosisMean_CD.gif'
		plot '$wrkdir/${filename}_stripped.dat' using 1:5 title "${title}:Trace 1", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:8 title "Trace 2", \\
		 '$wrkdir/${filename}_stripped.dat' using 1:11 title "Trace 3",  \\
		 '$wrkdir/${filename}_stripped.dat' using 1:14 title "Trace 4",\\
		 '$wrkdir/${filename}_stripped.dat' using 1:17 title "Trace 5"  with lines


		quit
		PLOT
		

	end




exit 0