#!/usr/bin/python

############
#Things to do#
#1) test python list object file list input
#2) allow to parse list of files seperated by "," on the command line
#
############

"""
Usage compareGoodRun2Data.py [options]

-i  input file(s)          You may specify a single file containing lumi sections, use wildcard resolution here, or specify a file with a list of other files in it.
-g  good run list(s)       Same as the input 
-o  optional output file   Default is ./compare.out
-h --help                  Brings up help

Wild cards are permitted in the input file name or the good run file name provided they follow the usage of the glob module. Please enclose any strings which contain wildcards in quotes, or the script will fail.
"""

import sys
import getopt
import types
import re
import glob

def usage():
    print __doc__

   

def openGeneralFile(path,operation='r'):
    """
    Opens a fill with some error handling for failed opening.

    Arg is path/filename of file to be opened.

    Returns a file object.
    """
    file=None
    try:
        file=open(path,operation)
    except IOError:
        print "Failed to open file: " + path + ".  Skipping"

    return file

def openManyFiles(object):
    input_d={}
    for element in object:
        element=re.sub("\n","",element)
        if element:
            newInputFile=openGeneralFile(element)
            try:
                input=eval(newInputFile.read())
                dataType=type(input)
                if dataType==types.DictType:
                    input_d.update(input)
                else:
                    print "Subfile " + element + " does not contain an expected dictionary type object. skipping"
            except SyntaxError:
                print "Can't understand the information in subfile " + element + ". skipping"
            except AttributeError:
                print "Skipping subfile " + element + "."

            if newInputFile:
                newInputFile.close()
    return input_d

                
def openInputFile(Path):
    """Opens the input file. For now can handle a file that contains a dictionary, or a file that contains a list of other files that contain a dictionary.

    Arg is a path/filename of file to be opened.

    Returns a dictionary object.
    """
    input_d={}
    dataType=None
    path_l=glob.glob(Path)
    for path in path_l:
        print path
    
        inputFile=openGeneralFile(path)
        if not inputFile:
            print "Critical error opening file " + path + ". Exiting."
            sys.exit(2)
        try:
            input=eval(inputFile.read())
            dataType=type(input)
        except SyntaxError:
            inputFile.seek(0)
            input_d.update(openManyFiles(inputFile))
        if dataType == types.DictType:
            input_d.update(input)
        elif dataType == types.ListType:
            input_d.update(openManyFiles(input))
        if not input_d:
            print "Could not load json. Unrecognizable file format(s)."
            sys.exit(2)
    
        if inputFile:
            inputFile.close()
        
    return input_d



def compareRunLists(runMasterList_d, runList_d):
    """Compares 2 dictionaries of runlists. runList is compared to runMasterList. Elements in runMasterList but not runList are recorded in a dictionary.

    Args (runMasterList_d,runList_d)

    Returns a dictionary of runs that runList lacks from the master.
    """

    missedRuns_d={}
    
    for runNumber in runMasterList_d:
        if runList_d.has_key(runNumber):
            missedLumiSection_l=compareLumiSections(runMasterList_d[runNumber],
                                                    runList_d[runNumber])
            missedRuns_d[runNumber]=missedLumiSection_l
        else:
            missedRuns_d[runNumber]=runMasterList_d[runNumber]

    return missedRuns_d



def compareLumiSections(lumiMaster_l,lumi_l):
    missedLumiSection_l=[]
    startFalse=0
    endFalse=0
    for masterLumiSection_l in lumiMaster_l:
        previousInRange=True
        currentInRange=False
        for lumi in range(masterLumiSection_l[0],masterLumiSection_l[1]+1,1):
            currentInRange=False
            for lumiSection_l in lumi_l:
                if lumi in range(lumiSection_l[0],lumiSection_l[1]+1,1):
                    currentInRange=True
            if currentInRange==True:
                if previousInRange==False:
                    endFalse=lumi-1
                    missedLumiSection_l.append([startFalse,endFalse])
                previousInRange=True
            else:
                if previousInRange==True:
                    startFalse=lumi
                previousInRange=False
        if currentInRange==False:
           endFalse=masterLumiSection_l[1]
           missedLumiSection_l.append([startFalse,endFalse]) 
    return missedLumiSection_l


def printMissedRuns(missedRuns_d,outfile):
    """Writes run/lumi list for good runs missed in the data.
    Args (missedRuns_d,outfile)
    """
    outFile=openGeneralFile(outfile,'w')
    missedRuns_l=[]
    outFile.write("{")
    if missedRuns_d:
        missedRunsTemp_l=missedRuns_d.keys()
        for missedRunTemp in missedRunsTemp_l:
            if missedRuns_d[missedRunTemp]:
                missedRuns_l.append(int(missedRunTemp))
            else:
                del missedRuns_d[missedRunTemp]
        missedRuns_l.sort()
        print missedRuns_l
        if missedRuns_l:
            for missedRun in missedRuns_l:
                if missedRuns_d[str(missedRun)]:
                    outFile.write("\"%i\": %s"%(missedRun,missedRuns_d[str(missedRun)]))
                    if missedRun != missedRuns_l[-1]:
                        outFile.write(",\n")

    outFile.write("}")                
    outFile.close()            
    

def main(argv):
   
    outputFile="compare.out"
    inputFile=None
    goodRunFile=None
    
    
    try:
        opts,args = getopt.getopt(argv, "ho:i:g:", ["help"])
    except getopt.GetoptError:
        print "Unrecognized options or incorrect input. Please see usage below.\n"
        usage()
        sys.exit(2)
    for opt,arg in opts:
        if opt in ("-h","--help"):
            usage()
            sys.exit()
        else:
            if opt == '-o':
                outputFile=arg 
            if opt == '-i':
                inputFile=arg
            if opt == '-g':
                goodRunFile=arg
  

    if (not inputFile) or (not goodRunFile):
        print "Please specify input files and good run files. If you have specified them, be sure that they follow correct usage.\n"
        usage()
        sys.exit(2)
    
    input_d=openInputFile(inputFile)
    goodRun_d=openInputFile(goodRunFile)
    missedRuns_d=compareRunLists(goodRun_d, input_d)
    printMissedRuns(missedRuns_d,outputFile)




if __name__=="__main__":
    main(sys.argv[1:])
