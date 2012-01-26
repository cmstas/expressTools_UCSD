#!/bin/bash

. loadConfig.sh $1

for Dataset in $Datasets; do

	MergingDir="/data/tmp/$USER"                                                     #location of the directory used for merging and logging
	HadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}"   #long term storage of ntupled datasets
	CMSSWDir="${OSGCode}/${CMSSWRelease}_${CMS2Tag}/src"                             #location of compiled release on gw2  
	StartDir="$PWD"
	DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
	DatasetDir="${DatasetDir_tmp:1}"                                                     #dataset name with "/" replaced with "_", used as the dir name for the dataset ntuples
	DatasetHadoopDir="${HadoopDir}/${DatasetDir}"                                        #full path to the hadoop dir where the dataset is stored
	DatasetSubDir=${StartDir}/${DatasetDir}                                              #location where the accounting is done to keep track of which files have been ntupled, merged, etc
	UnmergedDatasetDir="${DatasetHadoopDir}/${CMSSWRelease}_${CMS2Tag}"                  #location of unmerged ntuples on hadoop
	MergedDatasetDir="${DatasetHadoopDir}/${CMSSWRelease}_${CMS2Tag}_merged/${CMS2Tag}"  #location of the merged nutples on hadoop
	#MergingDir="${MergingDir}/${DatasetDir}/${CMS2Tag}"                                  #temporary disk for merging ntuples

	#set up accounting directories
	[ ! -d "${DatasetSubDir}" ] && echo Create ${DatasetSubDir} && mkdir ${DatasetSubDir}
	[ ! -f "${DatasetSubDir}/a.list" ]  && echo Create ${DatasetSubDir}/a.list && touch ${DatasetSubDir}/a.list
	[ ! -d "${DatasetSubDir}/newC" ] && echo Create ${DatasetSubDir}/newC && mkdir ${DatasetSubDir}/newC
	[ ! -d "${DatasetSubDir}/oldC" ] && echo Create ${DatasetSubDir}/oldC && mkdir ${DatasetSubDir}/oldC
	[ ! -d "${DatasetSubDir}/output" ] && echo Create ${DatasetSubDir}/output && mkdir ${DatasetSubDir}/output
	[ ! -d "${DatasetSubDir}/submitting_log" ] && echo Create ${DatasetSubDir}/submitting_log && mkdir ${DatasetSubDir}/submitting_log
	[ ! -d "${DatasetSubDir}/merging_log" ] && echo Create ${DatasetSubDir}/merging_log && mkdir ${DatasetSubDir}/merging_log
	
	#set up hadoop directories
	[ ! -d "${HadoopDir}" ] && echo Create ${HadoopDir} && mkdir ${HadoopDir}
	[ ! -d "${DatasetHadoopDir}" ] && echo Create ${DatasetHadoopDir} && mkdir ${DatasetHadoopDir}
	[ ! -d "${UnmergedDatasetDir}" ] && echo Create ${UnmergedDatasetDir} && mkdir -p ${UnmergedDatasetDir}
	[ ! -d "${MergedDatasetDir}" ] && echo Create ${MergedDatasetDir} && mkdir -p ${MergedDatasetDir}
	#[ ! -d "${MergedDatasetDir}/${CMS2Tag}" ] && echo Create ${MergedDatasetDir}/${CMS2Tag} && mkdir ${MergedDatasetDir}/${CMS2Tag}
	#[ ! -d "${MergedDatasetDir}/${CMS2Tag}/temp" ] && echo Create ${MergedDatasetDir}/${CMS2Tag}/temp && mkdir ${MergedDatasetDir}/${CMS2Tag}/temp
	[ ! -d "${MergedDatasetDir}/temp" ] && echo Create ${MergedDatasetDir}/temp && mkdir ${MergedDatasetDir}/temp

    #set up nfs directories
	[ ! -d "$NFSDir/${DatasetDir}" ] && echo Create  $NFSDir/${DatasetDir} && mkdir $NFSDir/${DatasetDir}
	[ ! -d "$NFSDir/${DatasetDir}/${CMS2Tag}" ] && echo Create $NFSDir/${DatasetDir}/${CMS2Tag} && mkdir $NFSDir/${DatasetDir}/${CMS2Tag}
	[ ! -d "$NFSDir/${DatasetDir}/${CMS2Tag}/temp" ] && echo Create $NFSDir/${DatasetDir}/${CMS2Tag}/temp && mkdir $NFSDir/${DatasetDir}/${CMS2Tag}/temp
	
	#set up temp mergind directories
	[ ! -d "${MergingDir}" ] && echo Create  ${MergingDir} && mkdir ${MergingDir}
	[ ! -d "${MergingDir}/${DatasetDir}" ] && echo Create  ${MergingDir}/${DatasetDir} && mkdir ${MergingDir}/${DatasetDir}
	[ ! -d "${MergingDir}/${DatasetDir}/${CMS2Tag}" ] && echo Create  ${MergingDir}/${DatasetDir}/${CMS2Tag} && mkdir ${MergingDir}/${DatasetDir}/${CMS2Tag}
	[ ! -d "${MergingDir}/${DatasetDir}/${CMS2Tag}/temp" ] && echo Create  ${MergingDir}/${DatasetDir}/${CMS2Tag}/temp && mkdir ${MergingDir}/${DatasetDir}/${CMS2Tag}/temp
	[ ! -d "${MergingDir}/${DatasetDir}/${CMS2Tag}/failed" ] && echo Create  ${MergingDir}/${DatasetDir}/${CMS2Tag}/failed && mkdir ${MergingDir}/${DatasetDir}/${CMS2Tag}/failed
	
#	while [ 1 ]; do
		echo $MergingDir
		source checkAndSubmit.sh $1 $CMSSWDir $Dataset $DatasetSubDir $DatasetHadoopDir
#		sleep 5400

		#source checkAndMerge.sh $1 $UnmergedDatasetDir $DatasetSubDir $MergingDir $MergedDatasetDir $DatasetDir
#		sleep 5400
#	done

done

 
