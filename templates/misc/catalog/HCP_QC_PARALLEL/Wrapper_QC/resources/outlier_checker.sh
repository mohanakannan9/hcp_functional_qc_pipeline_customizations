#!/bin/bash

#This script will check for outliers

paramsFile=$1
jsession=$2

source $paramsFile

#####################################################################
#
# Needs - scan_details.csv file
#         level2QC_SCANID.xml file
#
######################################################################

#####################################################################
#
# Variables used in params file
#
# host
# project
# workdir
# functional_usable_scanids - array
# xnat_id
# sessionId
#
######################################################################


#####################################################################
#
# CONSTANTS
#
######################################################################

BINDIR=@PIPELINE_DIR_PATH@/bin
PIPELINE_HOME=@PIPELINE_DIR_PATH@

MY_CURL_CONNECTION_TIMEOUT=
MY_CURL_RETRY=
MY_CURL_RETRY_MAXTIME=
#MY_CURL_OPTIONS=" -k --connect-timeout=$MY_CURL_CONNECTION_TIMEOUT --retry=$MY_CURL_RETRY --retry-max-time=$MY_CURL_RETRY_MAXTIME "
MY_CURL_OPTIONS=" -k "

MY_OUTLIER_RESOURCE_NAME="level2qc_xnat_qcAssessmentData"
VALIDATION_XSL_FILE=$PIPELINE_HOME/catalog/validation_tools/resources/svrl/nrg_iso_svrl_for_xslt2.xsl
OUTLIER_XSL_FILE=$PIPELINE_HOME/catalog/HCP_QC_PARALLEL/Wrapper_QC/resources/check_outliers.xsl


schematron_folder=$workdir/outlier_files
mkdir -p $schematron_folder

###########################################################################################
#
#
# Validate each QC for outliers. The cut-offs would depend on project and scan type
#
#
############################################################################################

curl $MY_CURL_OPTIONS --cookie "JSESSIONID=$jsession" -X GET  "${host}data/archive/projects/${project}/resources/${MY_OUTLIER_RESOURCE_NAME}/files?format=zip" > $workdir/${MY_OUTLIER_RESOURCE_NAME}.zip  


pushd $schematron_folder
  unzip -j $workdir/${MY_OUTLIER_RESOURCE_NAME}.zip 
  cp $PIPELINE_HOME/catalog/validation_tools/resources/site_imports.xsl .
popd



################################################################################################
#
#  GET scan information - this has already been done by the functional_batch_script_generator script
#
#################################################################################################

scanDetailsCSV=${workdir}/scan_details.csv


scan_count=${#functional_usable_scanids[@]}

declare -i scan_count_lastindex=${scan_count}-1

createReport=0

for (( i=0; i <= ${scan_count_lastindex}; i++ ))
do
   my_scan=${functional_usable_scanids[$i]}
   series_description=`grep ",\"/data/experiments/${xnat_id}/scans/${my_scan}\"" $scanDetailsCSV |  awk '{split($0,a,","); print a[5];}' | sed 's/\"//g'`
   #Get the validation document - level2qc_xnat_qcAssessmentData/series_description_rules.sch
   schematron_file=$schematron_folder/${series_description}_rules.sch
   if [ ! -e $schematron_file ]; then
       schematron_file=$schematron_folder/rules.sch
   fi
   if [ -e $schematron_file ]; then
   	   createReport=1	
	   schematron_rule_xsl_file=$schematron_folder/${series_description}_rules.xsl    
	   $PIPELINE_HOME/validation-tools/validation-transform -o $schematron_rule_xsl_file $schematron_file $VALIDATION_XSL_FILE 
	   #Check the QCAssessment XML against the Schematron rule file
	   qcFileName=$workdir/level2QC_${my_scan}.xml
	   scanReport=$workdir/${my_scan}_report.xml
	   $PIPELINE_HOME/validation-tools/validation-transform -o $scanReport $qcFileName $schematron_rule_xsl_file 
	   #Create a XSL which print the check results into proper format
	   $PIPELINE_HOME/validation-tools/validation-transform -o $workdir/${my_scan}_report.txt $scanReport $OUTLIER_XSL_FILE session_label=$sessionId series_description=$series_description
   fi	
done

if [ $createReport=1 ]; then
	session_outlier_report_file=$workdir/${sessionId}_report.dat
	touch $session_outlier_report_file
	#Construct a file which summarizes all results
	for (( i=0; i <= ${scan_count_lastindex}; i++ ))
	do
	  my_scan=${functional_usable_scanids[$i]}
	  echo "***********************************************************************************" >> $session_outlier_report_file 	
	  cat  $workdir/${my_scan}_report.txt >> $session_outlier_report_file
	  echo "***********************************************************************************" >> $session_outlier_report_file 	
	done
fi


exit 0;