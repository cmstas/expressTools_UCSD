#! /bin/bash

. loadConfig.sh $1
Dataset=$2

StartDir="$PWD"
DatasetDir_tmp=`echo $Dataset |sed -e 's?/?_?g' `
DatasetDir="${DatasetDir_tmp:1}"                                                 #dataset name with "/" replaced with "_", used as the dir name for the dataset ntuples

DatasetSubDir=${StartDir}/${DatasetDir}_${CMSSWRelease}_${CMS2Tag}               #location where the accounting is done to keep track of which files have been ntupled, merged, etc
MergingDir="/data/tmp/$USER"                                                     #location of the directory used for merging and logging
HadoopDir="/hadoop/cms/store/user/${HadoopUserDir}/${CMSSWRelease}_${CMS2Tag}"   #long term storage of ntupled datasets
DatasetHadoopDir="${HadoopDir}/${DatasetDir}"                                        #full path to the hadoop dir where the dataset is stored
UnmergedDatasetDir="${DatasetHadoopDir}/unmerged"                  #location of unmerged ntuples on hadoop
MergedDatasetDir="${DatasetHadoopDir}/merged"  #location of the merged nutples on hadoop


#set up accounting directories
[ ! -d "${DatasetSubDir}" ] && echo Create ${DatasetSubDir} && mkdir ${DatasetSubDir}
[ ! -d "${DatasetSubDir}/newC" ] && echo Create ${DatasetSubDir}/newC && mkdir ${DatasetSubDir}/newC
[ ! -d "${DatasetSubDir}/oldC" ] && echo Create ${DatasetSubDir}/oldC && mkdir ${DatasetSubDir}/oldC
[ ! -d "${DatasetSubDir}/merging_log" ] && echo Create ${DatasetSubDir}/merging_log && mkdir ${DatasetSubDir}/merging_log

#set up hadoop directories
[ ! -d "${HadoopDir}" ] && echo Create ${HadoopDir} && mkdir ${HadoopDir}
[ ! -d "${DatasetHadoopDir}" ] && echo Create ${DatasetHadoopDir} && mkdir ${DatasetHadoopDir}
[ ! -d "${UnmergedDatasetDir}" ] && echo Create ${UnmergedDatasetDir} && mkdir -p ${UnmergedDatasetDir}
[ ! -d "${MergedDatasetDir}" ] && echo Create ${MergedDatasetDir} && mkdir -p ${MergedDatasetDir}
[ ! -d "${MergedDatasetDir}/temp" ] && echo Create ${MergedDatasetDir}/temp && mkdir ${MergedDatasetDir}/temp

#set up temp mergind directories
#may want to eventually change this path to something better than datasetname/tag
[ ! -d "${MergingDir}" ] && echo Create  ${MergingDir} && mkdir ${MergingDir}
[ ! -d "${MergingDir}/${DatasetDir}" ] && echo Create  ${MergingDir}/${DatasetDir} && mkdir ${MergingDir}/${DatasetDir}
[ ! -d "${MergingDir}/${DatasetDir}/${CMS2Tag}" ] && echo Create  ${MergingDir}/${DatasetDir}/${CMS2Tag} && mkdir ${MergingDir}/${DatasetDir}/${CMS2Tag}
[ ! -d "${MergingDir}/${DatasetDir}/${CMS2Tag}/temp" ] && echo Create  ${MergingDir}/${DatasetDir}/${CMS2Tag}/temp && mkdir ${MergingDir}/${DatasetDir}/${CMS2Tag}/temp
[ ! -d "${MergingDir}/${DatasetDir}/${CMS2Tag}/failed" ] && echo Create  ${MergingDir}/${DatasetDir}/${CMS2Tag}/failed && mkdir ${MergingDir}/${DatasetDir}/${CMS2Tag}/failed

[ ! -f $DatasetSubDir/a.runs.list.tmp ] && echo Create $DatasetSubDir/a.runs.list.tmp && touch $DatasetSubDir/a.runs.list.tmp

##### Set up a cmssw environment. This will set up root for the merging. Probably could do this in a more controlled way (you know, without including the kitchen sink), but that is for a later date. #####
if [ ! -d $CMSSWLocation ]; then
	echo "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Exiting."
	which mail >& /dev/null && mail -s "Error: Cannot find directory for checked out CMSSW Location, $CMSSWLocation. Will not merge any files, since we need to set up a CMSSW environment." "$UserEmail"
	exit 1
fi
cd $CMSSWLocation
eval `scramv1 runtime -sh`
cd -
#############################################

TOOL_DIR=$PWD  
dateS=`date '+%Y.%m.%d-%H.%M.%S'`
echo Start Merging
echo $dateS

if [ ! -f $LibMiniFWLite ]; then
	echo "ERROR LibMiniFWLite $LibMiniFWLite does not exist. Will not merge. Exiting."
	which mail >& /dev/null && mail -s "ERROR LibMiniFWLite $LibMiniFWLite does not exist. Will not merge. Exiting." "$UserEmail"
	exit 1
fi
FreeSpace=`df /data/tmp | grep -v "Filesystem" | awk '{print $4}'`
if [ $FreeSpace -lt $MergeSpace ]; then 
	echo "ERROR less than $MergeSpace kb of space left on /data/tmp. Will not merge. Exiting."
	echo "If the threshold is too high, you may change the required space in config $1 by modifying variable MergeSpace."
	which mail >& /dev/null && mail -s "ERROR less than $MergeSpace kb of space left on /data/tmp. Will not merge. Exiting." "$UserEmail" < `echo "If the threshold is too high, you may change the required space in config $1 by modifying variable MergeSpace."`
	exit 1
fi



cd $DatasetSubDir
# get list of files which were not linked to the grouped
[ ! -f "grouped.list" ]  && touch grouped.list
cat grouped.list | grep ".root" > files.grouped
ls ${UnmergedDatasetDir} | grep  ".root" |grep -v ".log" |while read -r f; do
grep ${f} files.grouped >& /dev/null || echo ${f} ; done >files.ls

# copy current list (made by submitter)
'cp' ${DatasetSubDir}/a.runs.list.tmp ${DatasetSubDir}/runs.all.express
grep ^[1-9] runs.all.express | awk '{print $1}' | sort -g | uniq > runs.txt
cat files.ls | while read -r fr; do
	#examples
	##store_data_Run2011A_Photon_AOD_May10ReReco-v1_0005_F44A69EC-207C-E011-850D-001A64789D1C_999999.root
	##store_data_Run2011A_Photon_AOD_PromptReco-v4_000_167_913_1E4DDB3C-88A3-E011-86AB-BCAEC5329728.root
	## expect to find something of the form blah_blah_number_number_number-stuf.root, will extract the "stuff" part
    f=${fr%.root}  #remove root from the end
	f=${f##*_} #remove all the words and numbers seperated by underscores from the filename
	run=`grep  $f runs.all.express | awk '{print $1}'`
	(( run >= MinRunNumber )) && (( run <= MaxRunNumber )) && echo $run $f `grep $fr files.ls`
   
done > files.runs.ls
grep -v ^[1-9]  files.runs.ls >& /dev/null && echo Corrupt  files.runs.ls && exit 33

grep store files.runs.ls | cut -d" " -f1 | sort | uniq | while read -r rn; do 
    if [ ! -d "${rn}" ] ; then 
		mkdir ${rn}
		rnL=`echo ${rn} | cut -c1-3`  #I don't think this is needed anymore
		rnR=`echo ${rn} | cut -c4-6`  #I don't think this is needed anymore
    fi
done
grep store files.runs.ls | while read -r rn fo fr; do 
    if [ ! -h "$rn/$fr" ] ; then
		ln -s ${UnmergedDatasetDir}/${fr} ${rn}/${fr}
		sleep 1
		rnL=`echo ${rn} | cut -c1-3`       #I don't think this is needed anymore
		rnR=`echo ${rn} | cut -c4-6`   #I don't think this is needed anymore
		fLog=`echo ${fr} | sed -e 's/.root/.log/g' `
		echo ${fr}  >>  grouped.list
    fi
done

ls newC/ | grep C$ | while read -r c; do 
    oC=oldC/${c}
    nC=newC/${c}
    if [ ! -f ${oC} ] ; then 
	echo "New file was generated last time: shouldn't happen. Do manually"
	exit 36
    fi
    echo "WARNING : ${nC} is still in the merge queue : check it. File probably missing"
done

ls -d [1-9]* | while read -r rn; do
    (( rn < MinRunNumber )) && (( rn > MaxRunNumber )) && continue
    count=0 
    sec=-1
    cTot=`ls ${rn} | grep -c root`
    curCount=0
    refCount=0
    ls -tr ${rn} | grep ".root"$ | while read -r f; do
	(( cTot-- ))
	(( count++ ))
	scriptC=comb${rn}_${sec}.C; s=${scriptC}_temp
	startNew="NO" 
	(( curCount == 0 )) && startNew="YES"
	if [ "${startNew}" == "YES" ] ; then
	    (( sec++ ))
	    scriptC=comb${rn}_${sec}.C; s=${scriptC}_temp
      # 
	    if [ -f "${s}" ] ; then
		echo "Old ${s} not closed. Something is wrong" 
		exit 35
	    fi
	    (( seNext=sec+1 ))
	    scriptNext=comb${rn}_${seNext}.C
	    (( sePrev=sec-1 ))
	    scriptPrev=comb${rn}_${sePrev}.C
	  # need to decide here what to do
	  # the cleanest is to start a new file; unfortunately this means small files will be present
	  # the alternatives are too complicated
	    if [ -f "oldC/${scriptC}" ] ; then
		fileFound=`grep -c ${f} oldC/${scriptC}`
		if (( fileFound == 1 ))  ; then
		    (( curCount=0 ))
		    (( refCount++ ))
		    (( sec-- )) 
		    if (( cTot == 0 )) ; then
			# this is the last time we are in this loop
			nRef=`grep -v "e->Merge" oldC/${scriptC} | grep -c ".root" `
			if (( refCount != nRef )) ; then
			    echo "File mismatch at last point in ${scriptC}: ${refCount} != ${nRef} "
			    exit 40
			fi
			refCount=0
		    fi
		    continue
		else
		    (( haveNext=0 ))
		    [ -f "oldC/${scriptNext}" ] && haveNext=`grep -c ${f} oldC/${scriptNext}`
		    nRef=`grep -v "e->Merge" oldC/${scriptC} | grep -c ".root" `
		    if (( refCount != nRef )) ; then 
			echo "File mismatch at ${scriptC}  roll: ${refCount} != ${nRef}"
			exit 40
		    fi
		    if (( haveNext==1 )) ; then
			(( curCount=0 )) 
			refCount=1
			# after this the sec should increment and naturally go to next file
			continue
		    fi
		fi
		if (( fileFound > 1 || haveNext > 1 )); then
		    echo "Something is wrong: multiple copies of $f in merge scripts"
		    exit 38
		fi
		echo "Old merge ${scriptC} present: will not remerge"
		(( sec++ ))
		scriptC=comb${rn}_${sec}.C; s=${scriptC}_temp
	    fi
	    echo "New/updated end merge ${scriptC} " 
	
	    echo -e "void comb${rn}_${sec}(){\n gSystem->Load(\"${TOOL_DIR}/${LibMiniFWLite}\");\n" >> ${s}
	    echo -e "\n\tTTree::SetMaxTreeSize(8000000000);" >> ${s}   #set the max size of merged root files to 8 Gb
	    echo -e "\n\te = new TChain(\"Events\");\n "  >> ${s}
	fi
	echo -e "\n\te->Add(\"${rn}/${f}\");">> ${s}
	(( curCount++ ))
	closeC="NO"
	(( curCount == 50 || cTot == 0 ))  && closeC="YES"
	if [ "${closeC}" == "YES" ] ; then
	    echo -e "\n\te->Merge(\"${MergingDir}/${DatasetDir}/${CMS2Tag}/temp/merged_ntuple_${rn}_${sec}_ready.root\",\"fast\");\n}" >> ${s}
	    [ ! -f "oldC/${scriptC}" ] && echo "New ${scriptC} " && mv -f ${s} newC/${scriptC}
	    if [ -f "${s}" -a -f "oldC/${scriptC}" ] ; then
		isSame=`diff ${s} oldC/${scriptC} | grep -c ".root"`
		if [ "${isSame}" != "0" ] ; then 
		    echo "Override old ${scriptC} not possible" 
		    'rm' ${s} 
		    exit 37
		fi
		[ "${isSame}" == "0" ]  &&  mv -f ${s} newC/${scriptC}
	    fi
      (( curCount=0 ))
	fi
    done
    resE="$?"
    (( resE > 20 )) && echo Exited with $resE && exit $resE
done

#echo Testing only && exit 30

'rm' -f merge.list
touch merge.list
ls newC/*.C | while read -r  nC ;  do 
    oC=`echo ${nC} | sed -e "s?newC/?oldC/?g"` 
    [ ! -f "${oC}" ] && echo $nC >> merge.list
    if [ -f "${oC}" ] ; then 
	nDiffs=`diff $nC $oC | grep -c ".root"`
	if (( nDiffs > 0 )) ; then
	    echo "New File ${nC} overlaps with old ${oC} "
	    exit 37
	else
	    echo "Warning: $nC and $oC are both present. They're the same here. Still, shouldn't happen"
	fi
    fi
done 

cat merge.list | grep C$ | while read -r f ;  do 
    echo $f
    root -l -b -q $f
    nC=${f}
    oC=`echo ${nC} | sed -e "s?newC/?oldC/?g"`
    fDest=`grep Merge ${nC} | tr '\"' '\n' | grep _ready`
    if [ "x${fDest}" == "x" ] ; then
		echo "Corrupt ${nC}"
		'rm' ${fDest}
		exit 38
    fi
    if [ -s "${fDest}" ] ; then
		echo "all done with ${fDest} , copy $nC to $oC"
		fDGood=`echo ${fDest} | sed -e 's/_ready//g;s?/temp/?/?g'`
		mv ${fDest} ${fDGood}
		mv ${nC} ${oC}
		chmod a-w ${oC}
		fDGood_hadoop=`echo ${fDGood} | sed -e "s?\${MergingDir}/\${DatasetDir}/\${CMS2Tag}?\${MergedDatasetDir}?g;s?/hadoop??g"` 
		echo ${fDGood}
		echo ${MergingDir}
		echo ${MergedDatasetDir}
		echo ${fDGood_hadoop}
		hadoop fs -copyFromLocal  ${fDGood} ${fDGood_hadoop}
	
		copyE="$?"
		[ "$copyE" != 0 ] && 'rm' /hadoop${fDGood_hadoop} && hadoop fs -copyFromLocal  ${fDGood} ${fDGood_hadoop} 
       
		fSize_in=` ls -l ${fDGood}|awk '{print $5}' `
		fSize_out=` ls -l /hadoop${fDGood_hadoop}|awk '{print $5}' `
		echo source file $fSize_in
		echo destination file $fSize_out
		if [ "$fSize_in" -ne  "$fSize_out" ]; then
			'rm' /hadoop${fDGood_hadoop}
			hadoop fs -copyFromLocal  ${fDGood} ${fDGood_hadoop}	    
		elif [ "$fSize_in" ==  "$fSize_out" ]; then 
			'rm' ${fDGood}
		else
			echo Error while copying from /data/tmp to hadoop && exit 59 
		fi
    fi
done >& merging_log/merging.log.`date '+\%Y.\%m.\%d-\%H.\%M.\%S'`
#now move done files to merged
find ${MergingDir}/ -name merged_ntuple\*_ready.root | while read -r f ; do
    echo ${f}
    fo=`echo $f | sed -e 's/_ready//g;s?/temp/?/failed?g'`
    mv ${f} ${fo}
done



cd $TOOL_DIR
dateS=`date '+%Y.%m.%d-%H.%M.%S'`
echo Merging is Done
echo $dateS
