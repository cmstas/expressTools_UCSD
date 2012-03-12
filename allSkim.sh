#!/bin/bash 

# export VDT_LOCATION=/data/vdt
# export EDG_WL_LOCATION=$VDT_LOCATION/edg
# source /data/vdt/setup.sh 

echo "allSkim.sh PID is $$"

ConfigFiles=$@

while [1]; do

	for Config in $ConfigFiles; do
		. loadConfig.sh $Config
		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			touch /data/tmp/${USER}/${DatasetDir}/checkAndRunSkim.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkAndRunSkim.log
			./checkAndRunSkim.sh $Config $Dataset >> /data/tmp/${USER}/${DatasetDir}/checkAndRunSkim.log 2>&1  #don't run this process in the background, don't want to kill the system by skimming too many datasets at once
		done
		sleep 15
		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			touch /data/tmp/${USER}/${DatasetDir}/checkSkimErrors.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkSkimErrors.log
			./checkSkimErrors.sh $Config $Dataset >> /data/tmp/${USER}/${DatasetDir}/checkSkimErrors.log 2>&1 &
		done

	done
	sleep 7200
done




