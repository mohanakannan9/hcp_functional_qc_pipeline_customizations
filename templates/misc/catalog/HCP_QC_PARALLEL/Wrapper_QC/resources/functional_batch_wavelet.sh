#!/bin/bash 

#Given a params file and an index of the scan as input argument,
#this script would generate the WAVELET Stats for the scan
#The scan is picked up from the array using the $SGE_TASK_ID for the given task

my_sge_task_id=$1
paramsFile=$2
isStructural=$3

source $paramsFile;

my_scan=${functional_usable_scanids[$my_sge_task_id]}


SCRIPT_PATH=$PATH_TO_PYTHON_SCRIPT/WaveletStatistics/WaveletStatistics.py
FUNCTIONAL_PLOT_GENERATOR=@PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/WaveletKurtosis/resources/generate_plots.csh


source $SETUP_SCRIPTS/epd-python_setup.sh; 

pushd ${workdir}/RAWNIFTI/${my_scan}
  python $SCRIPT_PATH  -D $workdir/RAWNIFTI/${my_scan} -N *.nii.gz -O $wavelet_kurtosis_dir/${my_scan}
popd


pushd $wavelet_kurtosis_dir
	if [ $isStructural = no ] ; then
	 $FUNCTIONAL_PLOT_GENERATOR $sessionId $wavelet_kurtosis_dir/${my_scan}   $wavelet_kurtosis_dir/${my_scan} $my_scan	
	fi
popd

exit 0;

