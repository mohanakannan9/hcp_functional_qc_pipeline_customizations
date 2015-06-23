#!/bin/bash

#This script will submit to the SGE jobs to process the Funcational scans

########################################
#
# COMMANDLINE ARGUMENTS
#
#########################################

paramsFile=$1
declare -i scan_count=$2
script_file=$3


########################################
#
# CONSTANTS
#
#########################################

source @PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/Wrapper_QC/resources/config/level2qc.config


########################################
#
# START
#
#########################################

source $paramsFile

scan_count=${#functional_usable_scanids[@]}

declare -i scan_count_lastindex=${scan_count}-1

echo "Scan count is $scan_count_lastindex"

########################################
#
# GET SCAN META DETAILS
#
#########################################


scanDetailsCSV=${workdir}/scan_details.csv

restPath="${host}data/archive/projects/${project}/subjects/${subjectlabel}/experiments/${sessionId}/scans?columns=ID,xnat:imageScanData/frames,type,series_description&format=csv"

curl -k -u ${user}:${passwd} -G "$restPath" > $scanDetailsCSV

####################################################
#
# PROCESS A SCAN ONLY IF IT HAS $MIN_FRAME_COUNT
#
#####################################################

doEndStep=0

for (( i=0; i <= ${scan_count_lastindex}; i++ ))
do
   my_scan=${functional_usable_scanids[$i]}
   jobname_root=${xnat_id}_Scan${my_scan}
   #
   #As per Mike Harms run the functional processing only if the number of frames is more than a threshold (MIN_FRAME_COUNT)
   #
   frames=`grep ",/data/experiments/${xnat_id}/scans/${my_scan}" $scanDetailsCSV |  awk '{split($0,a,","); print a[3];}'`
   if [ $frames -gt $MIN_FRAME_COUNT ] ; then
	   qsub $SGE_OPTS -o ${builddir}/${sessionId}/logs/getScansNifti_${my_scan}.log -e ${builddir}/${sessionId}/logs/getScansNifti_${my_scan}.err  -N ${jobname_root}_GETNIFTI $BINDIR/functional_batch_getScans.sh $i $paramsFile NIFTI
	   qsub $SGE_OPTS -o ${builddir}/${sessionId}/logs/getScansDicom_${my_scan}.log -e ${builddir}/${sessionId}/logs/getScansDicom_${my_scan}.err -N ${jobname_root}_GETDICOM $BINDIR/functional_batch_getScans.sh $i $paramsFile DICOM

	   qsub $SGE_OPTS -N ${jobname_root}_FOURIER -o ${fourier_slope_statistics_dir}/${my_scan}/fourierstats.log -e ${fourier_slope_statistics_dir}/${my_scan}/fourierstats.err -hold_jid ${jobname_root}_GETNIFTI $BINDIR/functional_batch_fourierstatistics.sh $i $paramsFile no
	   qsub $SGE_OPTS -N ${jobname_root}_MOTION -hold_jid ${jobname_root}_GETNIFTI -o ${motionoutlierdir}/${my_scan}/motionoutlier.log -e ${motionoutlierdir}/${my_scan}/motionoutlier.err $BINDIR/functional_batch_motionoutlier.sh $i $paramsFile
	   qsub $SGE_OPTS -N ${jobname_root}_BIRN -hold_jid ${jobname_root}_GETDICOM -o $birndir/$my_scan/birn.log -e $birndir/$my_scan/birn.err $BINDIR/functional_batch_birn_human.sh $i $paramsFile
	   qsub $SGE_OPTS -N ${jobname_root}_WAVELET -hold_jid ${jobname_root}_GETNIFTI -o $wavelet_kurtosis_dir/$my_scan/wavelet.log -e $wavelet_kurtosis_dir/${my_scan}/wavelet.err $BINDIR/functional_batch_wavelet.sh $i $paramsFile no
	   qsub $SGE_OPTS -N ${jobname_root}_CREATE_ASSESSOR -hold_jid ${jobname_root}_FOURIER,${jobname_root}_MOTION,${jobname_root}_BIRN,${jobname_root}_WAVELET -o ${builddir}/${sessionId}/logs/${jobname_root}_create_assessor.log -e ${builddir}/${sessionId}/logs/${jobname_root}_create_assessor.err $BINDIR/create_singlescan_functional_qc.sh $i $paramsFile
	   doEndStep=1
   fi
done

###############################################################################################
# When all the scans are processed, perform cleanup, update workflow, send email notifications
###############################################################################################

job_id_pattern="${xnat_id}_Scan*"

if [ $doEndStep -eq 1 ] ; then
	qsub  $SGE_OPTS  -hold_jid $job_id_pattern -o ${builddir}/${sessionId}/logs/functional_batch_end.log -e ${builddir}/${sessionId}/logs/functional_batch_end.err $BINDIR/functional_batch_end.sh $paramsFile
fi

exit 0;
