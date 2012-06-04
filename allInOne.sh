#! /bin/bash
#source some initial things for working with the grid 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 


ConfigFiles=$@ #list of config files specified by the user on the command line
echo $ConfigFiles
Config=$ConfigFiles
#while [ 1 ]; do
      #for Config in $ConfigFiles; do #loop over the config files and use each one to run whileloop.sh
		. loadConfig.sh $Config  #load the configuration file specified by the user
		Datasets=`echo $Datasets | sed 's/,/ /g'`
		for Dataset in $Datasets; do #loop over all of the datasets listed in the config file
	        #call the script to submit jobs
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			mkdir -p /data/tmp/${USER}/${DatasetDir}
			touch /data/tmp/${USER}/${DatasetDir}/checkAndSubmit.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkAndSubmit.log
			
			pid=`echo $DatasetDir | sed -e 's/-/_/g'`_submit
			eval "a=\$$pid"
			kill -0 $a > /dev/null 2>&1
			if [ $? != 0 ]; then
				./checkAndSubmit.sh $Config $Dataset 2>&1 | ./appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkAndSubmit.log &
				eval "$pid=$!"
			fi
		done
		sleep 5400

		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			#echo $MergingDir
		    #call the script to merge output files
			touch /data/tmp/${USER}/${DatasetDir}/checkAndMerge.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkAndMerge.log
			
			pid=`echo $DatasetDir | sed -e 's/-/_/g'`_merge
			eval "a=\$$pid"
			kill -0 $a > /dev/null 2>&1
			if [ $? != 0 ]; then
				./checkAndMerge.sh $Config $Dataset 2>&1 | ./appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkAndMerge.log & # changed to merge in the background 
				eval "$pid=$!"
			fi
		done
		sleep 5400

		for Dataset in $Datasets; do
			DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
			DatasetDir="${DatasetDir_tmp:1}"
			#call the script to check for erros in the merging step
			touch /data/tmp/${USER}/${DatasetDir}/checkMergeErrors.log && chmod a+r /data/tmp/${USER}/${DatasetDir}/checkMergeErrors.log
			
			pid=`echo $DatasetDir | sed -e 's/-/_/g'`_error
			eval "a=\$$pid"
			kill -0 $a > /dev/null 2>&1
			if [ $? != 0 ]; then
				./checkMergeErrors.sh $Config $Dataset 2>&1 | ./appendTimeStamp.sh >> /data/tmp/${USER}/${DatasetDir}/checkMergeErrors.log &
				eval "$pid=$!"
			fi
		done

		sleep 15
   	#done
#done







