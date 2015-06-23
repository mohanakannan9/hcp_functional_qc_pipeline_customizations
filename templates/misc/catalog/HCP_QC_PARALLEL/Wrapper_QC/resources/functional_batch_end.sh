#!/bin/bash

#This script will submit to the SGE jobs to process the Funcational scans

paramsFile=$1


source $paramsFile

#####################################################################
#
# CONSTANTS
#
######################################################################

BINDIR=@PIPELINE_DIR_PATH@/bin
PIPELINE_HOME=@PIPELINE_DIR_PATH@
PIPELINE_RELATIVE_PATH="HCP_QC_PARALLEL/Wrapper_QC/FunctionalLevel2QC_End_v2.0.xml"
PIPELINE_NAME=$PIPELINE_HOME/$PIPELINE_RELATIVE_PATH

#############################################################################################
#
#  GET a jsession
#
##############################################################################################
MY_CURL_OPTIONS=" -k "


jsession=`curl  $MY_CURL_OPTIONS -u $u:$passwd ${host}data/JSESSION`
if [ $? -ne 0 ] ; then
	echo "Unable to get a jsession Aborting!"
	exit 1
fi



###########################################################################################
#
#
# Validate each QC for outliers. The cut-offs would depend on project and scan type
#
#
############################################################################################



$PIPELINE_HOME/catalog/HCP_QC_PARALLEL/Wrapper_QC/resources/outlier_checker.sh $paramsFile $jsession

session_outlier_report_file=$workdir/${sessionId}_report.dat


#If any failed assert exists, email the summary file to a list of people

step_condition=" -parameter outlier_exists=0 "

if [ -e $session_outlier_report_file ]; then
	failed=`grep "Outlier Check: fail" $session_outlier_report_file`
	step_condition=" -parameter outlier_exists=1 "
	if [ X"$failed" == X ]; then
	 step_condition=" -parameter outlier_exists=0 "
	fi
fi



workflowID=`source $SETUP_SCRIPTS/epd-python_setup.sh; python $PIPELINE_HOME/catalog/ToolsHCP/resources/scripts/workflow.py -User $user -Password $passwd -Server $host -ExperimentID $xnat_id -ProjectID $project -Pipeline $PIPELINE_NAME -Status Queued -JSESSION $jsession`
if [ $? -ne 0 ] ; then
	echo "Fetching workflow for structural failed. Aborting!"
	exit 1
fi 


curl $MY_CURL_OPTIONS --cookie "JSESSIONID=$jsession" -X DELETE ${host}/data/JSESSION


$BINDIR/XnatPipelineLauncher -pipeline $PIPELINE_RELATIVE_PATH -id $xnat_id -host $aliasHost -u $user -pwd $passwd -dataType xnat:mrSessionData -label $sessionId -supressNotification -project $project -notify $useremail -notify $adminemail -parameter mailhost=$mailhost -parameter xnat_id=$xnat_id -parameter project=$project -parameter sessionId=$sessionId -parameter userfullname=$userfullname -parameter builddir=$builddir -parameter xnatserver=$xnatserver -parameter adminemail=$adminemail -parameter useremail=$useremail -workFlowPrimaryKey=$workflowID $step_condition 

exit 0;

