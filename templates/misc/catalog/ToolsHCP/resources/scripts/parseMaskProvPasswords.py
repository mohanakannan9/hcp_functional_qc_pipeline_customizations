'''
Created on Nov 28, 2012

@author: Tony
'''

import xml
import os
import time
import argparse
import xml.etree.ElementTree as ET


sTime = time.time()

#===============================================================================
# PARSE INPUT
#===============================================================================
parser = argparse.ArgumentParser(description="Script to parse provenance XNAT file ...")

parser.add_argument("-iU", "--User", dest="iUser", default='tony', type=str)
parser.add_argument("-iP", "--Password", dest="iPassword", type=str)
parser.add_argument("-iD", "--inputDir", dest="inputDir", type=str)
parser.add_argument("-iF", "--inputFile", dest="inputFile", type=str)
parser.add_argument("-iDF", "--inputDirFile", dest="inputDirFile", type=str)
parser.add_argument('--version', action='version', version='%(prog)s 0.1')

args = parser.parse_args()

iUser = args.iUser
iPassword = args.iPassword
inputDir = args.inputDir
inputFile = args.inputFile
inputDirFile = args.inputDirFile
#===============================================================================

if ( (inputDir == None) and (inputDirFile != None) ):
    inputFile = os.path.basename(inputDirFile)
    inputFileBase, inputFileExt = os.path.splitext(inputFile)
    inputDir = os.path.dirname(os.path.normpath(inputDirFile)) + os.sep
    
inputFilePPL = inputFileBase.split('_')[0]
inputFileBase = inputFileBase.split('_')[0]
outputFileAppend = '_Provenance'
outputDir = os.path.basename(inputDir)
outputDirFile = '%s%s%s%s' % (inputDir, inputFileBase, outputFileAppend, inputFileExt)

#inputFileId = open(inputDirFile, 'r')
#inputFileData = inputFileId.read()
#inputFileId.close()

ET.register_namespace('pip', 'http://nrg.wustl.edu/pipeline')
ET.register_namespace('prov', 'http://www.nbirn.net/prov')

inputFileDataET = ET.parse(inputDirFile)
#inputFileDataET = ET.fromstring(inputFileData)

#print inputFileDataET.getroot().attrib

for ResolvedStep in inputFileDataET.findall('{http://nrg.wustl.edu/pipeline}ResolvedStep'):
    for resolvedResource in ResolvedStep.findall('{http://nrg.wustl.edu/pipeline}resolvedResource'):
        for resolvedInput in resolvedResource.findall('{http://nrg.wustl.edu/pipeline}input'):
            for resolvedArgument in resolvedInput.findall('{http://nrg.wustl.edu/pipeline}argument'):
                
                resolvedArgumentAttrib = resolvedArgument.attrib
                resolvedArgumentVals = resolvedArgument.findall('{http://nrg.wustl.edu/pipeline}value')
                
                if (len(resolvedArgumentVals) == 1):
#                    print resolvedArgumentAttrib.get('id'), resolvedArgumentVals[0].text
                    if (resolvedArgumentAttrib.get('id') == 'password'):
                        resolvedArgument.find('{http://nrg.wustl.edu/pipeline}value').text = '*******'
                    
#outputFileId = open(inputDirFile + 'output.xml', 'wb')
#outputFileData = ET.tostring(inputFileDataET)
#outputFileId.write(ET.tostring(inputFileDataET))
#outputFileId.close()

inputFileDataET.write(outputDirFile, encoding='UTF-8')

print("Duration: %s" % (time.time() - sTime))






