#!/bin/bash

#Given a params file and an index of the scan as input argument,
#this script would get the NIFTI for a given scan
#The scan is picked up from the array using the $SGE_TASK_ID for the given task

my_sge_task_id=$1
paramsFile=$2
catalogName=$3

source $paramsFile


XNATDATACLIENT=@PIPELINE_DIR_PATH@/xnat-tools/XnatDataClient

my_scan=${functional_usable_scanids[$my_sge_task_id]}

restPath=${aliasHost}data/archive/experiments/${xnat_id}/scans/${my_scan}/resources/$catalogName/files?format=zip


destinationPath="${workdir}/RAW${catalogName}/${my_scan}"

pushd $destinationPath
$XNATDATACLIENT  -u $user -p $passwd -m GET -r "$restPath" 

unzip -oj $destinationPath/*.zip -d $destinationPath

\rm -f $destinationPath/*.zip

popd

exit 0;
