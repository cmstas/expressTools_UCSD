#### !/usr/local/bin/bash
export SCRAM_ARCH=slc5_ia32_gcc434
source /code/osgcode/cmssoft/cms/cmsset_default.sh
export SCRAM_ARCH=slc5_ia32_gcc434
source /code/osgcode/ucsdt2/gLite/etc/profile.d/grid_env.sh
echo Begin. Print self first
cat $0
echo $HOSTNAME
curDir=`pwd`
relDir=$1

fileCfg=$2

fileIn=$3

outputDir=$4

fileFormat=$8

#export DATASET_NAME=$5
#export CMS2_TAG=$6

#fExt=$4

#Go to the release base, setup there and then return to the jobdir
echo "Will work in" ${relDir} "and run" ${fileCfg} "in:"${fileIn}
cd ${relDir}
eval `scramv1 ru -sh`
cd ${curDir}

nEvents=-1

oDirBase=${curDir}

relBase=`echo $CMSSW_BASE | sed -e 's?\([^$]*\)/\([^$]*$\)?\2?g'`
[ "x${relBase}" == "x" ] && echo Release is not setup && exit 45

oDir=${oDirBase}/${relBase}

[ -d "${oDir}" ] && echo WARNING "destination ${oDir} already exists -- will overwrite"
export failMkDestDir=""
[ ! -d "${oDir}" ] && echo Create ${oDir} && mkdir ${oDir}
[ ! -d "${oDir}" ] &&  export failMkDestDir=yes
[ "x${failMkDestDir}" == "xyes" ] && echo failed to make destination dir && exit 46
[ ! -d "${oDir}/log" ] && echo Create ${oDir}/log && mkdir ${oDir}/log
[ ! -d "${oDir}/xml" ] && echo Create ${oDir}/xml && mkdir ${oDir}/xml

 input_data_Run=$7
 
 if [ "${fileFormat}" == "prompt"  ]; then
     fileOut=`echo ${fileIn} | sed -e 's?/?_?g;s?:?_?g;s/file__//g'` ##replace / or : by _; and remove file__
 elif [ "${fileFormat}" == "reco"  ]; then
     fileOut=`echo ${fileIn} | sed -e "s?/?_?g;s?:?_?g;s/file__//g;s?.root?_${input_data_Run}.root?g"` ##replace / or : by _; and remove file__
 else 
     echo failed to define fileFormat && exit 122 
 fi
 echo Will cmsRun ${fileCfg} with ${nEvents} input: ${fileIn} to ${fileOut}
export INPUT_FILE=${fileIn}
#[ "x${fExt}" == "x" ] && export OUTPUT_FILE=${oDir}/${fileOut}
#[ "x${fExt}" != "x" ] && export OUTPUT_FILE=${oDir}/${fileOut}.${fExt}
export OUTPUT_FILE=${oDir}/${fileOut}
export N_EVENTS=${nEvents}
export SKIP_EVENTS=0
export DATASET_NAME=$5
export CMS2_TAG=$6
echo INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE N_EVENTS=$N_EVENTS SKIP_EVENTS=$SKIP_EVENTS DATASET_NAME=$DATASET_NAME CMS2_TAG=$CMS2_TAG
#remove igtrace if you don't like too much stack trace info
igtrace cmsRun -e ${fileCfg} >& ${oDir}/log/${fileOut}.log
executable_success=$?
if [ $executable_success -ne 0 ]; then 
    echo cmsRun failed 
    cat  ${oDir}/${fileOut}.log
    exit 47
fi
cat ${oDir}/${fileOut}.log
xmlfileOut=`echo $fileOut | sed -e 's?.root??g'`
mv FrameworkJobReport.xml ${oDir}/xml/${xmlfileOut}.xml
echo Almost Done  at `date`
ls -ltrh ${oDir}

echo Done with step2  MC at `date`

ls -lh ./*
#now copy all files from local dir and subdirs to the storage place
nRootFile=0
find ./ -type f -name "*.root" | while read -r f; do 
   	nRootFile++
done
if [ $nRootFile -gt 1 }; then 
    echo There are more than one root files!!
    exit 48
fi

find ./ -type f | while read -r f; do 
    echo "doing lcg-cp"
    lcg-cp -b -D srmv2 --vo cms -t 2400 --verbose file:`pwd`/${f}  srm://bsrm-1.t2.ucsd.edu:8443/srm/v2/server?SFN=$outputDir/${f}
    stage_out_code=$?
    [ "$stage_out_code" -ne 0 ] && echo stageout failure once
    echo "doing lcg-ls"
    time lcg-ls -l -b -D srmv2 srm://bsrm-1.t2.ucsd.edu:8443/srm/v2/server?SFN=$outputDir/${f}
    fSize_in=` ls -l ${f}|awk '{print $5}' `
    fSize_out=` lcg-ls -l -b -D srmv2 srm://bsrm-1.t2.ucsd.edu:8443/srm/v2/server?SFN=$outputDir/${f}|awk '{print $5}' `
    echo source file $fSize_in
    echo destination file $fSize_out
    if [ "$fSize_in" -ne  "$fSize_out" ]; then
	echo "redo copy files"
	lcg-cp -b -D srmv2 --vo cms -t 2400 --verbose file:`pwd`/${f}  srm://bsrm-1.t2.ucsd.edu:8443/srm/v2/server?SFN=$outputDir/${f}
	stage_out_code=$?
	[ "$stage_out_code" -ne 0 ] && echo stageout failure twice
    fi 
done

