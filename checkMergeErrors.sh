#! /bin/bash

. loadConfig.sh $1
Dataset=$2

DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir="${DatasetDir_tmp:1}"                                                     #dataset name with "/" replaced with "_", used as the dir name for the dataset ntuples
StartDir=$PWD
DatasetSubDir=${StartDir}/${DatasetDir}_${CMSSWRelease}_${CMS2Tag}                   #location where the accounting is done to keep track of which files have been ntupled

cd $DatasetSubDir

if [ ! -d $LogDir/error ]; then
	mkdir -p $LogDir/error
	error=$?
	if [ $error != 0 ]; then
		echo "Error: Failed to make directory for consolidating merge errors, $LogDir/error. Exiting."
		exit $error
	fi
fi

echo looking for merge Error
[ -d merging_log ] && ls -d merging_log/merging*| while read -r f; do
cat ${f} | grep "Error"
done | uniq >& $LogDir/error/${DatasetDir}_merging_error 

[ ! -d merging_log ] && echo did not find merge log

echo $PWD
cat grouped.list |grep .root | while read -r f; do
	grep $f oldC/*.C >& /dev/null || echo "$f is not in merge";
done >& ${LogDir}/mismerging/${DatasetDir}_mismerging
