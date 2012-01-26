#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 


ConfigFiles=$@
echo $ConfigFiles

for Config in $ConfigFiles; do
	source whileloop.sh $Config &
	echo "whileloop.sh PID=$! for config $Config."

done






