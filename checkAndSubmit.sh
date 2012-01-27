#!/bin/bash

. loadConfig.sh $1
CMSSWDir=$2
Dataset=$3
DatasetSubDir=$4
DatasetHadoopDir=$5

#check for the existence of a few things before attempting to submit jobs
if [ ! -f "$NtupleConfig" ]; then
	echo "ERROR: Specified _cfg.py file \"$NtupleConfig\" does not exist. Will not submit jobs."
	exit 1
fi

if [ ! -f "$UserProxy" ]; then
	echo "ERROR: Specified proxy \"$UserProxy\" does not exist. Will not submit jobs."
	exit 1
fi

if [ ! -O "$UserProxy" ]; then
	echo "ERROR: The current user $USER does own the specified proxy \"$UserProxy\". Will not submit jobs."
	exit 1
fi


python getLFNList_reco.py --dataset=${Dataset}|grep .root  > ${DatasetSubDir}/a.runs.list.tmp.phedex


dbslist=`dbsql "find run, file where file.status=VALID and dataset=$Dataset and  run >=${MinRunNumber} and run <=${MaxRunNumber}"`
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


cat ${DatasetSubDir}/a.runs.list.tmp |grep .root > ${DatasetSubDir}/a.runs.list0.tmp

'cp' ${DatasetSubDir}/a.list ${DatasetSubDir}/a.list.old
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

cat > expressTools_UCSD_${DatasetSubDir##*/}.cmd <<@EOF
universe=vanilla
executable=$PWD/runFromOneCfg_noEvCheck.sh
arguments=$CMSSWRelease $NtupleConfig $input_data ${DatasetHadoopDir}/${CMSSWRelease}_$CMS2Tag $CMS2Tar $CMS2Tag $Dataset
transfer_executable=True
when_to_transfer_output = ON_EXIT
#the actual executable to run is not transfered by its name.
#In fact, some sites may do weird things like renaming it and such.
transfer_input_files = $PWD/$NtupleConfig,$PWD/$CMS2Tar
+DESIRED_Sites="UCSD" 
+Owner = undefined 
log=/data/tmp/$USER/${DatasetSubDir##*/}/${CMS2Tag}/condor_submit.log
output = ${DatasetSubDir}/output/1e.\$(Cluster).\$(Process).out
error  = ${DatasetSubDir}/output/1e.\$(Cluster).\$(Process).err
notification=Never
#x509userproxy=$ENV(X509_USER_PROXY)	
x509userproxy=$UserProxy
queue
	
@EOF
	
condor_submit expressTools_UCSD_${DatasetSubDir##*/}.cmd 
    done >& ${DatasetSubDir}/submitting_log/${subLog}
    curT=`date +%s`
   
fi

echo "Done submitting. Sleep now ... "
