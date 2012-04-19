#! /bin/bash

. loadConfig.sh $1
Dataset=$2

[ ! -d "${LogDir}" ] && echo Create ${LogDir} && mkdir -p ${LogDir}
[ ! -d "$LogDir/error" ] && echo Create $LogDir/error && mkdir -p $LogDir/error && chmod 777 $LogDir/error
[ ! -d "$LogDir/mismerging" ] && echo Create $LogDir/mismerging && mkdir -p $LogDir/mismerging && chmod 777 $LogDir/mismerging




CurDir=$PWD
DatasetDirTmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir="${DatasetDirTmp:1}" 
HadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}"   #long term storage of ntupled datasets
DatasetHadoopDir="${HadoopDir}/${DatasetDir}"                                    #full path to the hadoop dir where the dataset is stored
PhedexDir="/hadoop/cms/phedex"
StartDir="$PWD"
DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir="${DatasetDir_tmp:1}"                                                 #dataset name with "/" replaced with "_", used as the dir name for the dataset ntuples

DatasetSubDir=${StartDir}/${DatasetDir}_${CMSSWRelease}_${CMS2Tag}               #location where the accounting is done to keep track of which files have been ntupled, merged, etc
[ ! -d "${DatasetSubDir}" ] && echo Create ${DatasetSubDir} && mkdir ${DatasetSubDir}
[ ! -f "${DatasetSubDir}/a.list" ]  && echo Create ${DatasetSubDir}/a.list && touch ${DatasetSubDir}/a.list
[ ! -f "${DatasetSubDir}/grouped.list" ]  && echo Create ${DatasetSubDir}/grouped.list && touch ${DatasetSubDir}/grouped.list


##### Set up a cmssw environment. Needed to run fjr2json.py which is a cmssw python module. Probably could do this in a more controlled way (you know, without including the kitchen sink), but that is for a later date. #####
if [ ! -d $CMSSWLocation ]; then
	echo "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Exiting."
	which mail >& /dev/null && mail -s "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Will not merge any files, since we need to set up a CMSSW environment." "$UserEmail" < /dev/null
	exit 1
fi
cd $CMSSWLocation
eval `scramv1 runtime -sh`
cd -
#############################################
fjr2json.py /hadoop/cms/store/user/$HadoopUserDir/${CMSSWRelease}_${CMS2Tag}/${DatasetDir}/unmerged/xml/*.xml >& $LogDir/${DatasetDir}_json

cd ${DatasetSubDir}

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
	grep store a.list.new.resubmit | while read -r rn f; do 
		input_data="root://xrootd.unl.edu/$f"
		echo ${input_data}
		../submit.sh -e ../runFromOneCfg_noEvCheck.sh -a "$CMSSWRelease $NtupleConfig $input_data ${DatasetHadoopDir}/unmerged ${CMS2Tar##*/} $CMS2Tag $Dataset" -i "../$NtupleConfig,../$CMS2Tar" -u ${DatasetSubDir##*/} -l /data/tmp/${USER}/${DatasetDir}/resubmit/condor_submit_logs/condor_submit_$dateS.log -L /data/tmp/${USER}/${DatasetDir}/resubmit/std_logs/ -p $UserProxy 
	done >& submitting_log/${subLog}
fi



echo $Dataset
wc -l submit.list
echo submitting Error or not finished jobs 
cat $LogDir/${DatasetDir}_missing_files
# echo looking for merge Error
# [ -d merging_log ] && ls -d merging_log/merging*| while read -r f; do
# cat ${f} |grep "Error"
# done | uniq >&$LogDir/error/${DatasetDir}_merging_error 

# [ ! -d merging_log ] && echo did not find merge log

# echo $PWD
# cat grouped.list |grep .root | while read -r f; do
# 	grep $f oldC/*.C >& /dev/null || echo "$f is not in merge";
# done >& ${LogDir}/mismerging/${DatasetDir}_mismerging

# cd ../

# echo looking for skim Error
# ls ${NFSDir} >& /dev/null

# for SkimFilter in $SkimFilters; do
# 	SkimDir=${SkimFilter#ntupleFilter}
# 	SkimDir=${SkimDir%.cc}
# 	[ -d "${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log" ] && ls -d ${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log/*log* |while read -r f; do
# 		cat ${f}|grep "Error"
# 	done | uniq >&$LogDir/error/${DatasetDir}_${SkimDir}_error
# done

# [ ! -d "${NFSDir}/${DatasetDir}/${CMS2Tag}/${SkimDir}/skim_log" ] && echo did not find skim log



