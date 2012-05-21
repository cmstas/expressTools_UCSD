#!/bin/bash

. loadConfig.sh $1
Dataset=$2

StartDir="$PWD"
DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir="${DatasetDir_tmp:1}"                                                 #dataset name with "/" replaced with "_", used as the dir name for the dataset ntuples
HadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}"   #long term storage of ntupled datasets
DatasetHadoopDir="${HadoopDir}/${DatasetDir}"                                    #full path to the hadoop dir where the dataset is stored
DatasetSubDir=${StartDir}/${DatasetDir}_${CMSSWRelease}_${CMS2Tag}               #location where the accounting is done to keep track of which files have been ntupled, merged, etc
UnmergedDatasetDir="${DatasetHadoopDir}/unmerged"                                #location of unmerged ntuples on hadoop
MergedDatasetDir="${DatasetHadoopDir}/merged"                                    #location of the merged nutples on hadoop

#set up accounting directories
[ ! -d "${DatasetSubDir}" ] && echo Create ${DatasetSubDir} && mkdir ${DatasetSubDir}
[ ! -f "${DatasetSubDir}/a.list" ]  && echo Create ${DatasetSubDir}/a.list && touch ${DatasetSubDir}/a.list
[ ! -d "${DatasetSubDir}/submitting_log" ] && echo Create ${DatasetSubDir}/submitting_log && mkdir ${DatasetSubDir}/submitting_log
	
#set up hadoop directories
[ ! -d "${HadoopDir}" ] && echo Create ${HadoopDir} && mkdir ${HadoopDir}
[ ! -d "${DatasetHadoopDir}" ] && echo Create ${DatasetHadoopDir} && mkdir ${DatasetHadoopDir}
[ ! -d "${UnmergedDatasetDir}" ] && echo Create ${UnmergedDatasetDir} && mkdir -p ${UnmergedDatasetDir}


#check for the existence of a few things before attempting to submit jobs
if [ ! -f "$NtupleConfig" ]; then
	echo "ERROR: Specified _cfg.py file \"$NtupleConfig\" does not exist. Will not submit jobs."
	which mail >& /dev/null && mail -s "ERROR: Specified _cfg.py file \"$NtupleConfig\" does not exist. Will not submit jobs." "$UserEmail" < /dev/null
	exit 1
fi

if [ ! -f "$UserProxy" ]; then
	echo "ERROR: Specified proxy \"$UserProxy\" does not exist. Will not submit jobs."
	which mail >& /dev/null && mail -s "ERROR: Specified proxy \"$UserProxy\" does not exist. Will not submit jobs." "$UserEmail" < /dev/null
	exit 1
fi

if [ ! -O "$UserProxy" ]; then
	echo "ERROR: The current user $USER does own the specified proxy \"$UserProxy\". Will not submit jobs."
	which mail >& /dev/null && mail -s "ERROR: The current user $USER does own the specified proxy \"$UserProxy\". Will not submit jobs." "$UserEmail" < /dev/null
	exit 1
fi

##### Set up a cmssw environment. This will set up root for the merging. Probably could do this in a more controlled way (you know, without including the kitchen sink), but that is for a later date. #####
if [ ! -d $CMSSWLocation ]; then
	echo "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Exiting."
	which mail >& /dev/null && mail -s "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Will not merge any files, since we need to set up a CMSSW environment." "$UserEmail" < /dev/null
	exit 1
fi
cd $CMSSWLocation
eval `scramv1 runtime -sh`
cd -
#############################################


python getLFNList_reco.py --dataset=${Dataset} | grep .root  > ${DatasetSubDir}/a.runs.list.tmp.phedex #This python script shouldn't require anything special to run, but if it fails, it may require a valid cms environment. The json module didn't used to be included in the standard python install on uaf, but  now seems to be.


dbslist=`dbsql "find run, file where file.status=VALID and dataset=$Dataset and  run >=${MinRunNumber} and run <=${MaxRunNumber}" | grep store/ | grep .root`
if [ `printf "%s %s\n" $dbslist | wc -l` = `printf "%s %s\n" $dbslist | awk '{print $2}' | sort | uniq | wc -l` ]; then
    printf "%s %s\n" $dbslist > ${DatasetSubDir}/a.list.dbs
else
    printf "999999 %s\n" `printf "%s %s\n" $dbslist | awk '{print $2}' | sort | uniq` > ${DatasetSubDir}/a.list.dbs
fi

if [ -s "${DatasetSubDir}/a.list.dbs" ] ; then
     if [ -s "${DatasetSubDir}/a.runs.list.tmp.phedex" ]; then 
		 cat ${DatasetSubDir}/a.list.dbs|grep .root | while read -r rn f; do
			 grep $f  ${DatasetSubDir}/a.runs.list.tmp.phedex>& /dev/null && echo $rn $f  
	     done  &> ${DatasetSubDir}/a.runs.list.tmp 
     fi 
else
    echo a.list.dbs is empty   
    which mail >& /dev/null && mail -s "dbs query fails " "$UserEmail" < ${DatasetSubDir}/a.list.dbs.tmp 
    exit 99
fi


cat ${DatasetSubDir}/a.runs.list.tmp | grep .root > ${DatasetSubDir}/a.runs.list0.tmp

cat ${DatasetSubdir}/a.list ${DatasetSubDir}/a.list.old | sort | uniq | grep ".root" > a.list.old # this used to be a straight cp command, but it's better that always preserves a.list.old now
'cp' ${DatasetSubDir}/a.runs.list0.tmp ${DatasetSubDir}/a.list


#now we have the old list and the new full list. 
#The next is to get the list of new files (assumes old files were sent for processing, if not the recovery to be done manually)
#check for empty output
aSize=`grep store/ ${DatasetSubDir}/a.list | grep -c root`
[ "${aSize}" == "0" ] && echo "Failed to get file list" && exit 23
'rm' -f ${DatasetSubDir}/a.list.new; touch ${DatasetSubDir}/a.list.new; grep store ${DatasetSubDir}/a.list | while read -r rn f; do grep $f ${DatasetSubDir}/a.list.old >& /dev/null || echo $rn $f >> ${DatasetSubDir}/a.list.new; done
aNewSize=`grep -c store ${DatasetSubDir}/a.list.new`
echo "Will submit ${aNewSize} files"

# now let's decide where this goes
#get the jobstatus into a text file

nToSub=`grep -c store ${DatasetSubDir}/a.list.new `
echo $nToSub
echo ${DatasetSubDir##*/}

if (( nToSub > 0 )) ; then
    dateS=`date '+%Y.%m.%d-%H.%M.%S'`
    subLog=sub.log.${dateS}
    grep store ${DatasetSubDir}/a.list.new | while read -r rn f; do 
	input_data="root://xrootd.unl.edu/$f"
	input_data_run="$rn"
	
	#the run script takes arguments: baseReleaseDirectory configFile inputFile extensionToOutputFile
	#the output file will be a legal version of the inputFile name with : and / replaced by _ (see the script)


	./submit.sh -e $PWD/runFromOneCfg_noEvCheck.sh -a "$CMSSWRelease ${NtupleConfig##*/} $input_data ${DatasetHadoopDir}/unmerged ${CMS2Tar##*/} $CMS2Tag $Dataset" -i "$PWD/$NtupleConfig,$PWD/$CMS2Tar" -u ${DatasetSubDir##*/} -l /data/tmp/${USER}/${DatasetDir}/submit/condor_submit_logs/condor_submit_$dateS.log -L /data/tmp/${USER}/${DatasetDir}/submit/std_logs/ -p $UserProxy 
  
	done >& ${DatasetSubDir}/submitting_log/${subLog}
    curT=`date +%s`
   
fi

echo "Done submitting. Sleep now ... "
