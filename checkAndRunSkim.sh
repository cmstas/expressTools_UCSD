. loadConfig.sh $1

for Dataset in $Datasets; do

	DatasetDirTmp=`echo $Dataset |sed -e 's?/?_?g' `
	DatasetDir=`echo ${DatasetDirTmp:1} `	
	DatasetHadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}/${DatasetDir}" 
	MergedDatasetDir="${DatasetHadoopDir}/${CMSSWRelease}_${CMS2Tag}_merged/${CMS2Tag}"
	echo $MergedDatasetDir
	
	for SkimFilter in $SkimFilters; do
		SkimDir=${SkimFilter%.cc}
		SkimDir=${SkimDir#ntupleFilter}
		
		NFSDatasetDir="${NFSDir}/${DatasetDir}/${CMS2Tag}"
		
		
		[ ! -d "$NFSDatasetDir" ] && echo Create  $NFSDatasetDir && mkdir -p $NFSDatasetDir
		[ ! -d "$NFSDatasetDir/$SkimDir" ] && echo Create  $NFSDatasetDir/$SkimDir && mkdir $NFSDatasetDir/$SkimDir
		[ ! -d "$NFSDatasetDir/$SkimDir/skim_log" ] && echo Create  $NFSDatasetDir/$SkimDir/skim_log && mkdir $NFSDatasetDir/$SkimDir/skim_log
	
		echo "Start skims at "`date`
		dateS=`date '+%Y.%m.%d-%H.%M.%S'`

			find ${MergedDatasetDir} -name merged_ntuple_\*.root | while read -r f; do
				echo "                             "
				echo "Start ${SkimDir%Skim} skimming "
				echo "                             "
				fO=`echo ${f} | sed -e "s?${MergedDatasetDir}/merged?${NFSDatasetDir}/${SkimDir}/skimmed?g" `
				[ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} && root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"true\",\"$SkimFilter\",\"$LibMiniFWLite\")"
				[ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
			done >&  $NFSDatasetDir/$SkimDir/skim_log/Skim.log.${dateS}
		
		echo "Done skimming "`date`

	done
done