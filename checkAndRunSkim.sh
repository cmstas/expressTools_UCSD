#! /bin/bash

. loadConfig.sh $1
Dataset=$2

DatasetDirTmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir=`echo ${DatasetDirTmp:1} `	
DatasetHadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}/${DatasetDir}" 
MergedDatasetDir="${DatasetHadoopDir}/merged"                #location of the merged nutples on hadoop
#echo $MergedDatasetDir
NFSDatasetDir="${NFSDir}/${DatasetDir}/${CMS2Tag}"


#set up nfs directories
[ ! -d "$NFSDir/${DatasetDir}" ] && echo Create  $NFSDir/${DatasetDir} && mkdir $NFSDir/${DatasetDir}
[ ! -d "$NFSDatasetDir" ] && echo Create $NFSDatasetDir && mkdir $NFSDatasetDir
[ ! -d "$NFSDatasetDir/temp" ] && echo Create $NFSDatasetDir/temp && mkdir $NFSDatasetDir/temp
[ ! -d "${MergedDatasetDir}" ] && echo Create ${MergedDatasetDir} && mkdir -p ${MergedDatasetDir}

##### Set up a cmssw environment. This will set up root for the skimming. Probably could do this in a more controlled way (you know, without including the kitchen sink), but that is for a later date. #####
if [ ! -d $CMSSWLocation ]; then
	echo "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Exiting."
	which mail >& /dev/null && mail -s "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Will not merge any files, since we need to set up a CMSSW environment." "$UserEmail" < /dev/null
	exit 1
fi
cd $CMSSWLocation
eval `scramv1 runtime -sh`
cd -
#############################################

$SkimFilters=`echo $SkimFilters | sed 's/,/ /g'`
for SkimFilter in $SkimFilters; do
	SkimDir=${SkimFilter%.cc}
	SkimDir=${SkimDir#ntupleFilter}
	
	[ ! -d "$NFSDatasetDir/$SkimDir" ] && echo Create  $NFSDatasetDir/$SkimDir && mkdir $NFSDatasetDir/$SkimDir
	[ ! -d "$NFSDatasetDir/$SkimDir/skim_log" ] && echo Create  $NFSDatasetDir/$SkimDir/skim_log && mkdir $NFSDatasetDir/$SkimDir/skim_log
	
	echo "Start skims at "`date`
	dateS=`date '+%Y.%m.%d-%H.%M.%S'`

	find ${MergedDatasetDir} -name merged_ntuple_\*.root | while read -r f; do
		FreeSpace=`df /data/tmp | grep -v "Filesystem" | awk '{print $4}'`
		if [ $FreeSpace -lt $SkimSpace ]; then 
			echo "ERROR less than $SkimSpace kb of space left on /data/tmp. Will not skim. Exiting."
			echo "If the threshold is too high, you may change the required space in config $1 by modifying variable SkimSpace."
			which mail >& /dev/null && mail -s "ERROR less than $SkimSpace kb of space left on $NFSDir. Will not skim. Exiting." "$UserEmail" < `echo "If the threshold is too high, you may change the required space in config $1 by modifying variable SkimSpace."`
			exit 1
		fi

		echo "                             "
		echo "Start ${SkimDir%Skim} skimming "
		echo "                             "
		fO=`echo ${f} | sed -e "s?${MergedDatasetDir}/merged?${NFSDatasetDir}/${SkimDir}/skimmed?g" `
		[ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} && root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"true\",\"$SkimFilter\",\"$LibMiniFWLite\")"
		[ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
	done >&  $NFSDatasetDir/$SkimDir/skim_log/Skim.log.${dateS}
	
	echo "Done skimming "`date`

done
