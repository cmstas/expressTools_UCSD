#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 

echo "allSkim.sh PID is $$"

ConfigFiles=$@

#while [1]; do

	for Config in $ConfigFiles; do
		source checkAndRunSkim.sh $Config

	done
#	sleep 7200
#done




