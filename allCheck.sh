#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 


ConfigFiles=$@

for Config in $ConfigFiles; do
    source checkFailedJobs.sh $Config &
	echo "checkFailedJobs.sh PID is $$"
done


