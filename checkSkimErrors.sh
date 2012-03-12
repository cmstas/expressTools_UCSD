#! /bin/bash

. loadConfig.sh $1
Dataset=$2
DatasetDirTmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir=`echo ${DatasetDirTmp:1} `	

echo looking for skim Error
#ls ${NFSDir} >& /dev/null #why is this here?

for SkimFilter in $SkimFilters; do
	SkimDir=${SkimFilter#ntupleFilter}
	SkimDir=${SkimDir%.cc}
	[ -d "${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log" ] && ls -d ${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log/*log* |while read -r f; do
		cat ${f}|grep "Error"
	done | uniq >&$LogDir/error/${DatasetDir}_${SkimDir}_error
done

[ ! -d "${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log" ] && echo did not find skim log
