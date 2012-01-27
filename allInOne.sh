#!/bin/bash
#source some initial things for working with the grid 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 


ConfigFiles=$@ #list of config files specified by the user on the command line
echo $ConfigFiles

for Config in $ConfigFiles; do #loop over the config files and use each one to run whileloop.sh
	source whileloop.sh $Config &  #want to remove the source and change to ./ , need to investigate whether the exports and source for vdt above must be in all other scripts
	echo "whileloop.sh PID=$! for config $Config."

done






