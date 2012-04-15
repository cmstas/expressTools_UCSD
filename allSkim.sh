#!/bin/bash 

# export VDT_LOCATION=/data/vdt
# export EDG_WL_LOCATION=$VDT_LOCATION/edg
# source /data/vdt/setup.sh 

echo "allSkim.sh PID is $$"

ConfigFiles=$@

while [1]; do

	for Config in $ConfigFiles; do
		. loadConfig.sh $Config
                $Datasets=`echo $Datasets | sed 's/,/ /g'`
		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			touch /data/tmp/${USER}/${DatasetDir}/checkAndRunSkim.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkAndRunSkim.log
			./checkAndRunSkim.sh $Config $Dataset 2>&1 | appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkAndRunSkim.log  #don't run this process in the background, don't want to kill the system by skimming too many datasets at once
		done
		sleep 15
		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			touch /data/tmp/${USER}/${DatasetDir}/checkSkimErrors.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkSkimErrors.log
			./checkSkimErrors.sh $Config $Dataset 2>&1 | appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkSkimErrors.log &
		done

	done
	sleep 7200
done




