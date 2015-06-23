#!/bin/bash -e

#Given a params file and an index of the scan as input argument,
#this script would generate the MotionOutlier Stats for the scan
#The scan is picked up from the array using the $SGE_TASK_ID for the given task

my_sge_task_id=$1
paramsFile=$2


source $paramsFile

MOTION_SCRIPT=@PIPELINE_DIR_PATH@/catalog/HCP_QC_PARALLEL/MotionOutliers/resources/motion_qc.sh


my_scan=${functional_usable_scanids[$my_sge_task_id]}


pushd ${workdir}/RAWNIFTI/${my_scan}
  $MOTION_SCRIPT *nii.gz $workdir/RAWNIFTI/${my_scan} $motionoutlierdir/$my_scan $motionoutlierdir/$my_scan/${my_scan}_mo.dat ${motionoutlierdir_temp}
popd

exit 0;


