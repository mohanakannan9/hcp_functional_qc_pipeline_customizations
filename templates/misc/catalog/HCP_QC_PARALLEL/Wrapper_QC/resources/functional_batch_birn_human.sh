#!/bin/bash

#Given a params file and an index of the scan as input argument,
#this script would generate the BIRN Stats for the scan
#The scan is picked up from the array using the $SGE_TASK_ID for the given task

my_sge_task_id=$1
paramsFile=$2

##############################################
#
# Import the paths from configuration file
#
##############################################

source @PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/Wrapper_QC/resources/config/level2qc.config

source $SETUP_SCRIPTS/bxh_xcede_tools_setup.sh;


bindir=$BXH_XCEDE_TOOLS_HOME/bin

source $paramsFile;



my_scan=${functional_usable_scanids[$my_sge_task_id]}

derivedDataQA="$birndir/${my_scan}"
bxhOutputFile=$birndir/${my_scan}_image.xml
seriesFullPath="${bxhOutputFile}:h"
seriesLabel="$seriesFullPath:t"


pushd ${workdir}/RAWDICOM/${my_scan}
  dicom2bxh --xcede  *.dcm $birndir/${my_scan}_image.xml
popd


#############################################################################
#  run analysis script
#############################################################################

date=`date`
echo $bindir/fmriqa_generate.pl $bxhOutputFile --overwrite --qalabel $sessionId":Scan"$my_scan "$derivedDataQA"

$bindir/fmriqa_generate.pl $bxhOutputFile  --overwrite --qalabel $sessionId":Scan"$my_scan "$derivedDataQA" 

exit 0;