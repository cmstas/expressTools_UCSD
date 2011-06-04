#!/usr/bin/env python

import sys,os,urllib,json,getopt

datasetpath = None
try:
    opts, args = getopt.getopt(sys.argv[1:], "", ["dataset="])
except getopt.GetoptError:
    print 'Unknown argument specifid: %s'%sys.argv[1:]
    sys.exit(2)

print opts
# extract dataset out of the options arrat
# for example [('--dataset','abc')]
for opt, arg in opts :
    if opt == "--dataset" :
        datasetpath = arg
    #if opt == "--lowrun" :
        #low_run = int(arg)
    #if opt == "--highrun" :
        #high_run = int(arg)    
if datasetpath == None:
    print 'Please specify dataset with --dataset'
    sys.exit(2)
url = 'http://cmsweb.cern.ch/phedex/datasvc/json/prod/filereplicas?block=' + datasetpath + '*'
result = json.load(urllib.urlopen(url))

for block in result['phedex']['block']:
    for filelist in block['file'] :
        #print filelist['name']
        for replica in filelist['replica'] :
            if replica['node']=="T2_US_UCSD" or replica['node']=="T2_US_Nebraska" or replica['node']=="T2_US_Caltech" or replica['node']=="T2_US_Wisconsin" or replica['node']=="T2_US_Florida" or replica['node']=="T2_US_Purdue" or replica['node']=="T1_US_FNAL_Buffer" or replica['node']=="T1_US_FNAL_MSS"  :
                lfn=filelist['name']
                #a1=os.path.dirname(lfn)
                #s1=os.path.basename(a1)
                #a2=os.path.dirname(a1)
                #s2=os.path.basename(a2)
                #run_number = int(s2+s1)
                #if run_number >= low_run and run_number <= high_run:
                print filelist['name']
