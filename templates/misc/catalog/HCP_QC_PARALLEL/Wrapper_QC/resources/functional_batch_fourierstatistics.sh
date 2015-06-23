#!/bin/bash

#Given a params file and an index of the scan as input argument,
#this script would generate the FourierStatistics for the scan
#The scan is picked up from the array using the $SGE_TASK_ID for the given task

my_sge_task_id=$1
paramsFile=$2
#Pass yes or no for isStructural
isStructural=$3

##############################################
#
# Import the paths from configuration file
#
##############################################

source @PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/Wrapper_QC/resources/config/level2qc.config

source $SETUP_SCRIPTS/epd-python_setup.sh;


source $paramsFile

my_scan=${functional_usable_scanids[$my_sge_task_id]}

FUNCTIONAL_PLOT_GENERATOR=@PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/FourierCoefficients/resources/generate_plots_functional.csh
STRUCTURAL_PLOT_GENERATOR=@PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/FourierCoefficients/resources/generate_plots_struc.csh

indir=${workdir}/RAWNIFTI/${my_scan}

inpattern="*.nii.gz"

outdir=${fourier_slope_statistics_dir}/${my_scan}


pushd $indir 
python $PATH_TO_PYTHON_SCRIPT/FourierStatistics/FourierSlope.py -D ${indir} -N $inpattern -O $outdir
popd

pushd ${fourier_slope_statistics_dir}
	if [ $isStructural = no ] ; then
	  $FUNCTIONAL_PLOT_GENERATOR $sessionId ${fourier_slope_statistics_dir}/${my_scan}  ${fourier_slope_statistics_dir}/${my_scan} $my_scan 
	else
	  $STRUCTURAL_PLOT_GENERATOR $sessionId ${fourier_slope_statistics_dir}/${my_scan} ${fourier_slope_statistics_dir}/${my_scan} $my_scan 
	fi
popd

exit 0;
