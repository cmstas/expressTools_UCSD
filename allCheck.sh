#!/bin/bash 
#export VDT_LOCATION=/data/vdt
#export EDG_WL_LOCATION=$VDT_LOCATION/edg
#source /data/vdt/setup.sh 


ConfigFiles=$@

while [ 1 ]; do
	for Config in $ConfigFiles; do
		. loadConfig.sh $Config
		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			touch /data/tmp/${USER}/${DatasetDir}/checkFailedJobs.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkFailedJobs.log
			./checkFailedJobs.sh $Config $Dataset >> /data/tmp/${USER}/${DatasetDir}/checkFailedJobs.log 2>&1 &
			echo "checkFailedJobs.sh PID is $$"
		done
		sleep 5400
	done
done



