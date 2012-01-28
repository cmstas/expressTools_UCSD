. loadConfig.sh $1

[ ! -d "${LogDir}" ] && echo Create ${LogDir} && mkdir -p ${LogDir}
[ ! -d "$LogDir/error" ] && echo Create $LogDir/error && mkdir -p $LogDir/error && chmod 777 $LogDir/error
[ ! -d "$LogDir/mismerging" ] && echo Create $LogDir/mismerging && mkdir -p $LogDir/mismerging && chmod 777 $LogDir/mismerging


for Dataset in $Datasets; do

	CurDir=$PWD
	DatasetDirTmp=`echo $Dataset |sed -e 's?/?_?g' `
	DatasetDir="${DatasetDirTmp:1}" 
	HadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}"   #long term storage of ntupled datasets
	DatasetHadoopDir="${HadoopDir}/${DatasetDir}"                                        #full path to the hadoop dir where the dataset is stored
	PhedexDir="/hadoop/cms/phedex"


	fjr2json.py /hadoop/cms/store/user/$HadoopUserDir/${CMSSWRelease}_${CMS2Tag}/${DatasetDir}/${CMSSWRelease}_${CMS2Tag}/xml/*.xml >& $LogDir/${DatasetDir}_json
	
	cd ${DatasetDir}
	
	cat a.list  > submit.list
	cat grouped.list |sed 's?_?/?g' |sed 's?store?/store?g'>  grouped.list.tmp
	cat submit.list | while read -r rn f; do
		grep ${f} grouped.list.tmp >& /dev/null || echo ${rn} ${f} ; 
	done >& $LogDir/${DatasetDir}_missing_files
	
	cat $LogDir/${DatasetDir}_missing_files| while read -r rn f; do
	    f_hadoop="$PhedexDir$f"
	
		if [ ! -s "$f_hadoop" ]; then
			echo $rn $f
		fi
    done >& $LogDir/${DatasetDir}_missing_files_20h_non_ucsd




    cat $LogDir/${DatasetDir}_missing_files| while read -r rn f; do
        f_hadoop="$PhedexDir$f"

		if [ -s "$f_hadoop" ]; then
			if test `find "$f_hadoop" -mmin +1200`; then
				echo $rn $f
			fi
		fi
	done >& $LogDir/${DatasetDir}_missing_files_20h


    [ ! -f "a.list.resubmit" ]  && echo Create a.list.resubmit && touch a.list.resubmit
	cat $LogDir/${DatasetDir}_missing_files_20h $LogDir/${DatasetDir}_missing_files_20h_non_ucsd | grep .root | sort | uniq > a.runs.list0.tmp.resubmit
	'cp' a.list.resubmit a.list.old.resubmit
	'cp' a.runs.list0.tmp.resubmit a.list.resubmit
	'rm' -f a.list.new.resubmit; touch a.list.new.resubmit; grep store a.list.resubmit | while read -r rn f; do grep $f a.list.old.resubmit >& /dev/null || echo $rn $f >> a.list.new.resubmit; done
	aNewSize=`grep -c store a.list.new.resubmit`
	echo "Will resubmit ${aNewSize} files"
	cat a.list.new.resubmit
	nToSub=`grep -c store a.list.new.resubmit `
	if (( nToSub > 0 )) ; then
		dateS=`date '+%Y.%m.%d-%H.%M.%S'`
		subLog=sub.log.${dateS}
		#'cp' ../expressTools_UCSD_${DatasetDir}.cmd expressTools_UCSD_${DatasetDir}_resubmit.cmd
		grep store a.list.new.resubmit | while read -r rn f; do 
			input_data="root://xrootd.unl.edu/$f"
			#python ../resubmit.py expressTools_UCSD_${DatasetDir}_resubmit.cmd ${input_data}
			echo ${input_data}
			#cd ${CurDir}
#	condor_submit ${DatasetDir}/expressTools_UCSD_${DatasetDir}_resubmit.cmd
			../submit.sh -e ../runFromOneCfg_noEvCheck.sh -a "$CMSSWRelease $NtupleConfig $input_data ${DatasetHadoopDir}/${CMSSWRelease}_${CMS2Tag} $CMS2Tar $CMS2Tag $Dataset" -i "../$NtupleConfig,../$CMS2Tar" -u $DatasetDir -l /data/tmp/${USER}/${DatasetDir}/resubmit/condor_submit_logs/condor_submit_$dateS.log -L /data/tmp/${USER}/${DatasetDir}/resubmit/std_logs/ -p $UserProxy 
			#cd ${CurDir}/${DatasetDir}
		done >& submitting_log/${subLog}
	fi
	
	
	
	echo $Dataset
	wc -l submit.list
	echo submitting Error or not finished jobs 
	cat $LogDir/${DatasetDir}_missing_files
	echo looking for merge Error
	ls -d merging_log/merging*| while read -r f; do
        cat ${f} |grep "Error"
    done | uniq >&$LogDir/error/${DatasetDir}_merging_error 

	echo $PWD
	cat grouped.list |grep .root | while read -r f; do
		grep $f oldC/*.C >& /dev/null || echo "$f is not in merge";
	done >& ${LogDir}/mismerging/${DatasetDir}_mismerging

	cd ../

	echo looking for skim Error
	ls ${NFSDir} >& /dev/null

	for SkimFilter in $SkimFilters; do
		SkimDir=${SkimFilter#ntupleFilter}
		SkimDir=${SkimDir%.cc}
		[ -d "${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log" ] && ls -d ${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log/*log* |while read -r f; do
			cat ${f}|grep "Error"
		done | uniq >&$LogDir/error/${DatasetDir}_${SkimDir}_error
	done

	[ ! -d "${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log" ] && echo did not find skim log

done

