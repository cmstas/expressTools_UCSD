
#! /usr/bin/python

import sys


def main(fileName):
    config={}
    file=open(fileName, 'r')
    print "Reading in the configuration from %s\n"%fileName
    for line in file:
        if "#" in line or line=="\n" or line==" ":
            continue
        [field,value]=line.split('=')
        field=field.strip()
        value=value.strip()
        config[field]=value
        print "%s = %s"%(field,value)
    print "\nModifying allInOne.sh"
    modifyAllInOne(config)
    print "Modifying whileloop.sh"
    modifyWhileLoop(config)
    print "Modifying CMS2 NTupleMaker Configuration File"
    modifyConfigFile(config)
    print "Modifying checkAndSubmit.sh"
    modifyCheckAndSubmit(config)
    print "Modifying checkAndMerge.sh"
    modifyCheckAndMerge(config)
    print "Modifying makeSkim.C"
    modifyMakeSkimC(config)
    

def modifyAllInOne(mod_d):
    input=open("allInOne.sh").readlines()
    output=open("allInOne.sh",'w')
    for line in input:
        if "#" not in line:
            if "cmssw_release=" in line:
                line="cmssw_release=%s\n"%mod_d['cmssw_release']
            if "cms2_tag=" in line:
                line="cms2_tag=%s\n"%mod_d['cms2_tag']
            if "dataset_names=" in line:
                line="dataset_names=\""
                for dataset in mod_d['dataset_names'].split(','):
                    line=line+"`echo %s` "%dataset.strip()
                line=line.strip()+"\"\n"
        output.write(line)
    output.close()
    

def modifyWhileLoop(mod_d):
    input=open("whileloop.sh").readlines()
    output=open("whileloop.sh",'w')
    for line in input:
        if "#" not in line:
            ## note this is one of those crazy var=`echo stuff` lines, need to fix
            if ("cmssw_dir=" in line) and ("cmssw_dir" in mod_d.keys()):
                line="cmssw_dir=`echo %s`\n"%mod_d['cmssw_dir']
            if "hadoop_dir=" in line:
                line="hadoop_dir=`echo %s`\n"%mod_d['hadoop_dir']   
            if "config_file=" in line:
                line="config_file=`echo %s`\n"%mod_d['config_file']
            if "out_dir=" in line:
                line="out_dir=`echo %s`\n"%mod_d['out_dir']
        output.write(line)
    output.close()


def modifyConfigFile(mod_d):
    input=open(mod_d['config_file']).readlines()
    output=open(mod_d['config_file'],'w')
    output.write("import sys, os, string\n")
    for line in input:
        if "#" not in line:
            if "input = cms.untracked.int32" in line:
                line="\tinput = cms.untracked.int32(%s)\n"%mod_d['maxEvents']
            if "process.GlobalTag.globaltag =" in line:
                #example FT_R_38X_V14A::All
                line="process.GlobalTag.globaltag = \"%s\"\n"%mod_d['globaltag']
        output.write(line)

    append1="process.source.fileNames = cms.untracked.vstring(os.environ[\'INPUT_FILE\'])"
    append2="process.source.skipEvents = cms.untracked.uint32(string.atoi(os.environ[\'SKIP_EVENTS\']))"
    append3="process.source.noEventSort = cms.untracked.bool(True)"
    append4="process.out.fileName = cms.untracked.string(os.environ[\'OUTPUT_FILE\'])"
    append5="process.eventMaker.datasetName = cms.string(os.environ[\'DATASET_NAME\'])"
    append6="process.eventMaker.CMS2tag = cms.string(os.environ[\'CMS2_TAG\'])"
    append7="process.maxEvents = cms.untracked.PSet(input = cms.untracked.int32(%s))"%mod_d['maxEvents']
    output.write("%s\n%s\n%s\n%s\n%s\n%s\n%s\n"%(append1,append2,append3,append4,append5,append6,append7))
    

    output.close()

def modifyCheckAndSubmit(mod_d):
    input=open("checkAndSubmit.sh").readlines()
    output=open("checkAndSubmit.sh",'w')
    for line in input:
        if "#" not in line:
            if "\twhich mail >& /dev/null && mail -s" in line:
                line="which mail >& /dev/null && mail -s \"dbs query fails \" %s < ${sd_sub_dir}/a.list.dbs.tmp\n"%mod_d['email']
        output.write(line)
    output.close()


def modifyCheckAndMerge(mod_d):
    input=open("checkAndMerge.sh").readlines()
    output=open("checkAndMerge.sh",'w')
    for line in input:
        if "#" not in line:
            if "gSystem->Load" in line and "libMiniFWLite.so" in line:
                line="          echo -e \"void comb${rn}_${sec}(){\\n gSystem->Load(\\\"${TOOL_DIR}/%s\\\");\\n\" >> ${s}\n"%mod_d['libMiniFWLite']
        output.write(line)
    output.close()
                

def modifyMakeSkimC(mod_d):
    input=open("makeSkim.C").readlines()
    output=open("makeSkim.C", 'w')
    for line in input:
        if "//" not in line:
            if "gSystem->Load(\"libMiniFWLite.so\");" in line:
                line="  gSystem->Load(\"%s\");\n"%mod_d['libMiniFWLite']
        output.write(line)
    output.close()


if __name__=="__main__":
    if sys.argv[1]:
        main(sys.argv[1])
    else:
        print "Usage: python editScripts.py [config file]"
        
