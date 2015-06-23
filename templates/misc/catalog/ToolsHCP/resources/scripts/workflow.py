'''
Created on Dec 6, 2013

@author: Mohana Ramaratnam (mohanakannan9@gmail.com)
'''
import argparse
import os
import re

import subprocess
import sys
import socket

import time
import urllib
import urllib2

import xml.etree.ElementTree as ET

from urllib2 import URLError, HTTPError
from ssl import SSLError


class Workflow(object):
    """Workflow Handler Class"""
    def __init__(self,User, Password, Server, JSESSIONID):
        super(Workflow, self).__init__()
        self.User = User
        self.Password = Password
        self.Server = Server
        self.JSESSION = JSESSIONID
        self.Timeout = 8
        self.TimeoutMax = 1024
        self.TimeoutStep = 8


    def createWorkflow( self, experimentID,projectID, pipeline,status):
        """Create a Workflow Entry and return the primary key of the inserted workflow"""
        WorkflowStrXML = '<wrk:Workflow data_type="xnat:mrSessionData"  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:wrk="http://nrg.wustl.edu/workflow" />'
        WorkflowDataElement = ET.fromstring(WorkflowStrXML)
        ET.register_namespace('wrk', 'http://nrg.wustl.edu/workflow')
        
        WorkflowDataElement.set('ID',experimentID)
        WorkflowDataElement.set('ExternalID',projectID)
        WorkflowDataElement.set('status',status)
        WorkflowDataElement.set('pipeline_name',pipeline)
        timeNow=time.localtime()
        xmlTime=time.strftime('%Y-%m-%dT%H:%M:%S', timeNow)
        prettyTimeNow=time.strftime('%Y-%m-%dT%H-%M-%S', timeNow)
        WorkflowDataElement.set('launch_time',xmlTime)
        WorkflowDataStr = ET.tostring(WorkflowDataElement)
        if sys.platform != 'win32':
           WorkflowWriteStr = '/tmp/Workflow_%s_%s.xml' % (experimentID,prettyTimeNow)
           with open(WorkflowWriteStr, 'wb') as outputFileObj:
             outputFileObj.write(WorkflowDataStr)
           #WorkflowSubmitStr = 'source $SCRIPTS_HOME/xnat-tools_setup.sh; $NRG_PACKAGES/tools/xnat-tools/StoreXML -u %s -p %s -host %s -location %s -allowDataDeletion true' % (self.User, self.Password, self.Server, WorkflowWriteStr)
           WorkflowSubmitStr = '$PIPELINE_HOME/xnat-tools/XNATRestClient -m PUT -user_session %s  -host %s -remote "REST/workflows?req_format=xml" -local %s' % (self.JSESSION, self.Server, WorkflowWriteStr)
           subprocess.call(WorkflowSubmitStr, shell=True, stdout = open("/dev/null", "w"))
           workflowID = self.getQueuedWorkflowIdAsParameter(pipeline,experimentID)
           return workflowID
        else:
           ET.dump(WorkflowDataElement)
           return -1
    #===============================================================================
    def getPipelineName(self, pipeline):
        pipeline.strip()
        slashIndex=pipeline.find('/')
        dotXMLIndex=pipeline.find('.xml')
        
        if (slashIndex == -1):
            retStr=pipeline
        else:
            retStr=pipeline[slashIndex+1:]
        if (dotXMLIndex == -1):
            return retStr
        else:        
            return retStr[0:dotXMLIndex]    

    #===============================================================================
       
    def getQueuedWorkflowIdAsParameter( self, pipeline, experimentID):
        """Get Workflow Data and Parse to extract the Queued Workflow DB primary key"""
        pipeline=self.getPipelineName(pipeline)
        restURL = self.Server + 'data/services/workflows/' + pipeline + '?display=LATEST&experiment=' + experimentID
        workflowidStr = ' '     

        restData = self.getURLStringUsingJSESSION( restURL)
        
        match=re.search('hidden_fields\[wrk_workflowData_id="(\d+)"\]',restData)
        if match:
            startIndx = match.start()
            endIndx = match.end()
            workflowPrimaryKeyStr = restData[startIndx:endIndx]
        match=re.match(r"hidden_fields\[wrk_workflowData_id=\"(\d+)\"\]",workflowPrimaryKeyStr)
        if (match):
            workflowidStr =  match.group(1)
        return workflowidStr   
    #===============================================================================
    def getURLStringUsingJSESSION( self, URL):
        """Get URL results as a string"""
        restRequest = urllib2.Request(URL)
        restRequest.add_header("Cookie", "JSESSIONID=" + self.JSESSION);
    
        while (self.Timeout <= self.TimeoutMax):
            try:
                restConnHandle = urllib2.urlopen(restRequest, None, self.Timeout)
            except HTTPError, e:
                if (e.code == 400):
                    return '404 Error'
                elif (e.code == 500):
                    return '500 Error'
                elif (e.code != 404):
                    self.Timeout += self.TimeoutStep
                    print 'HTTPError code: ' +str(e.code)+ '. Timeout increased to ' +str(self.Timeout)+' seconds for ' +URL
                else:
                    print e
                    break
                    
            except URLError, e:
                self.Timeout += self.TimeoutStep
                print 'URLError code: ' +str(e.reason)+ '. Timeout increased to ' +str(self.Timeout)+' seconds for ' +URL
            except SSLError, e:
                self.Timeout += self.TimeoutStep
                print 'SSLError code: ' +str(e.message)+ '. Timeout increased to ' +str(self.Timeout)+' seconds for ' +URL
            except socket.timeout:
                self.Timeout += self.TimeoutStep
                print 'Socket timed out. Timeout increased to ' +str(self.Timeout)+ ' seconds for ' +URL
                
            else:
                try:
                    ReadResults = restConnHandle.read()
                    return ReadResults
                    
                except HTTPError, e:
                    print 'READ HTTPError code: ' +str(e.code)+ '. File read timeout for ' +str(self.Timeout)+ ' seconds for ' +URL
                except URLError, e:
                    print 'READ URLError code: ' +str(e.reason)+ '. File read timeout for ' +str(self.Timeout)+' seconds for ' +URL
                except SSLError, e:
                    print 'READ SSLError code: ' +str(e.message)+ '. File read timeout for ' +str(self.Timeout)+' seconds for ' +URL
                except socket.timeout:
                    print 'READ Socket timed out. File read timeout for ' +str(self.Timeout)+ ' seconds for ' +URL
                    
        print 'ERROR: No reasonable timeout limit could be found for ' + URL
        sys.exit()

def main():
    #===============================================================================
    # Workflow Handling
    #===============================================================================
    
    parser = argparse.ArgumentParser(description="Script to generate workflow for XNAT pipeline")
    
    # MANDATORY....
    parser.add_argument("-User", "--User", dest="User", default=None, type=str)
    parser.add_argument("-Password", "--Password", dest="Password", default=None, type=str)
    parser.add_argument("-Server", "--Server", dest="Server", default=None, type=str)
    parser.add_argument("-ExperimentID", "--ExperimentID", dest="ExperimentID", default=None, type=str)
    parser.add_argument("-ProjectID", "--ProjectID", dest="ProjectID", default=None, type=str)
    parser.add_argument("-Pipeline", "--Pipeline", dest="Pipeline", default=None, type=str)
    parser.add_argument("-Status", "--Status", dest="Status", default='Queued', type=str)
    parser.add_argument("-JSESSION", "--JSESSION", dest="JSESSION", default=None, type=str)
    
    args = parser.parse_args()
    #MANDATORY....
    User = args.User
    Password = args.Password
    Server = args.Server
    ExperimentID = args.ExperimentID
    ProjectID=args.ProjectID
    Pipeline=args.Pipeline
    Status=args.Status
    JSESSION=args.JSESSION
    
    workflowObj=Workflow(User,Password,Server, JSESSION)
    workflowID=workflowObj.createWorkflow(ExperimentID, ProjectID, Pipeline,Status)
    print '%s' % (workflowID)


if  __name__ =='__main__':
    main()
