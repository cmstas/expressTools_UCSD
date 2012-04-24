#!/bin/bash
#source some initial things for working with the grid 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 


ConfigFiles=$@ #list of config files specified by the user on the command line
echo $ConfigFiles

while [ 1 ]; do
	for Config in $ConfigFiles; do #loop over the config files and use each one to run whileloop.sh
		. loadConfig.sh $Config  #load the configuration file specified by the user
		Datasets=`echo $Datasets | sed 's/,/ /g'`
		for Dataset in $Datasets; do #loop over all of the datasets listed in the config file
	        #call the script to submit jobs
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			mkdir -p /data/tmp/${USER}/${DatasetDir}
			touch /data/tmp/${USER}/${DatasetDir}/checkAndSubmit.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkAndSubmit.log
			./checkAndSubmit.sh $Config $Dataset 2>&1 | ./appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkAndSubmit.log &
		done
		sleep 5400

		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			#echo $MergingDir
		    #call the script to merge output files
			touch /data/tmp/${USER}/${DatasetDir}/checkAndMerge.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkAndMerge.log
			./checkAndMerge.sh $Config $Dataset 2>&1 | ./appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkAndMerge.log & # changed to merge in the background 
		done
		sleep 5400

		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			#call the script to check for erros in the merging step
			touch /data/tmp/${USER}/${DatasetDir}/checkMergeErrors.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkMergeErrors.log
			./checkMergeErrors.sh $Config $Dataset 2>&1 | ./appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkMergeErrors.log &
		done
		sleep 
   	done
done






