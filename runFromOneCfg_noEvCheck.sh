#### !/usr/local/bin/bash
#set up some preliminaries
source /code/osgcode/cmssoft/cmsset_default.sh  > /dev/null 2>&1
#export SCRAM_ARCH=slc5_amd64_gcc434
export SCRAM_ARCH=slc5_amd64_gcc462
echo $SCRAM_ARCH

#scram list

echo Begin. Print self first
cat $0
echo $HOSTNAME
oDir=`pwd`
CMSSWRelease=$1
fileCfg=$2
fileIn=$3
outputDir=$4
CMS2Tar=$5
CMS2Tag=$6

#checkout cmssw and untar the libraries and py files
scram list
scram project -n ${CMSSWRelease}_$CMS2Tag CMSSW $CMSSWRelease
if [ $? != 0 ]; then
	echo "ERROR: Failed to check out CMSSW release $CMSSWRelease. Exiting job without running."
fi
mv $CMS2Tar ${CMSSWRelease}_$CMS2Tag/
cd ${CMSSWRelease}_$CMS2Tag
tar -xzf $CMS2Tar #this is an overkill for now. we can experiment with dropping parts of it.
eval `scram runtime -sh`
#relBase=`echo $CMSSW_BASE | sed -e 's?\([^$]*\)/\([^$]*$\)?\2?g'` #whoever came up with this is pretty crazy, but there is a way easier way
#[ "x${CMSSWRelease}_$CMS2Tag" == "x" ] && echo Release is not setup && exit 45
if [ "${CMSSW_BASE##*/}" = "" ]; then
	echo "ERROR: Could not set up CMSSW environment. Exiting."
	exit 1
fi
cd -

# export SCRAM_ARCH=slc5_amd64_gcc434
# source /code/osgcode/cmssoft/cms/cmsset_default.sh
# export SCRAM_ARCH=slc5_amd64_gcc434
# source /code/osgcode/ucsdt2/gLite/etc/profile.d/grid_env.sh



#Go to the release base, setup there and then return to the jobdir
#echo "Will work in" ${CMSSWRelease} "and run" ${fileCfg} "in:"${fileIn}
#cd ${CMSSWRelease}
#source ../../setupSLC5.sh
#eval `scramv1 ru -sh`

#cd ${curDir}


#oDir=${oDirBase}/JobOutput

#### WARNING: must change these lines if ever want to do the ntupling at sites other than ucsd ####
[ -d "${oDir}" ] && echo WARNING "destination ${oDir} already exists -- will overwrite"
export failMkDestDir=""
[ ! -d "${oDir}" ] && echo Create ${oDir} && mkdir ${oDir}
[ ! -d "${oDir}" ] &&  export failMkDestDir=yes
[ "x${failMkDestDir}" == "xyes" ] && echo failed to make destination dir && exit 46
[ ! -d "${oDir}/log" ] && echo Create ${oDir}/log && mkdir ${oDir}/log 
[ ! -d "${oDir}/xml" ] && echo Create ${oDir}/xml && mkdir ${oDir}/xml


#files start with root://xrootd.unl.edu//store... using the xrootd system
# if [ "${fileFormat}" == "prompt"  ]; then
#     fileOut=`echo ${fileIn} | sed -e 's?/?_?g;s?:?_?g;s/root___xrootd.unl.edu__//g'` ##replace / or : by _; and remove file__
# elif [ "${fileFormat}" == "reco"  ]; then
#     fileOut=`echo ${fileIn} | sed -e "s?/?_?g;s?:?_?g;s/root___xrootd.unl.edu__//g;s?.root?_${input_data_Run}.root?g"` ##replace / or : by _; and remove root___xrootd.unl.edu__
# elif [ "${fileFormat}" == "mc"  ]; then
#     fileOut=`echo ${fileIn} | sed -e "s?/?_?g;s?:?_?g;s/root___xrootd.unl.edu__//g;s?.root?_${input_data_Run}.root?g"` ##replace / or : by _; and remove root___xrootd.unl.edu__
# else 
#     echo failed to define fileFormat && exit 122 
# fi


fileOut=`echo ${fileIn} | sed -e 's?/?_?g;s?:?_?g;s/root___xrootd.unl.edu__//g'` ##replace / or : by _; and remove file__
nEvents=-1
echo Will cmsRun -e ${fileCfg} with ${nEvents} input: ${fileIn} to ${fileOut}
export INPUT_FILE=${fileIn}
#[ "x${fExt}" == "x" ] && export OUTPUT_FILE=${oDir}/${fileOut}
#[ "x${fExt}" != "x" ] && export OUTPUT_FILE=${oDir}/${fileOut}.${fExt}
export OUTPUT_FILE=${oDir}/${fileOut}
export N_EVENTS=${nEvents}
export SKIP_EVENTS=0
export DATASET_NAME=$7
export CMS2_TAG=$CMS2Tag
echo INPUT_FILE=$INPUT_FILE OUTPUT_FILE=$OUTPUT_FILE N_EVENTS=$N_EVENTS SKIP_EVENTS=$SKIP_EVENTS DATASET_NAME=$DATASET_NAME CMS2_TAG=$CMS2_TAG
#remove igtrace if you don't like too much stack trace info
igtrace cmsRun -e ${fileCfg} >& ${oDir}/log/${fileOut}.log

executable_success=$?
if [ $executable_success -ne 0 ]; then 
    echo cmsRun failed 
    cat  ${oDir}/log/${fileOut}.log
    exit 47
fi
cat ${oDir}/log/${fileOut}.log
xmlfileOut=`echo $fileOut | sed -e 's?.root??g'`
mv FrameworkJobReport.xml ${oDir}/xml/${xmlfileOut}.xml
echo Almost Done  at `date`
ls -ltrh ${oDir}

echo Done with step2  MC at `date`

#cleanup
rm -rf ${CMSSWRelease}_$CMS2Tag

ls -lh ./*
#now copy all files from local dir and subdirs to the storage place
nRootFile=0
find ./ -type f -name "*.root" | while read -r f; do 
   	nRootFile=$(($nRootFile+1))
done
if [ $nRootFile -gt 1 ]; then 
    echo There are more than one root files!!
    exit 48
fi

#find ./ -type f | while read -r f; do 
find ./  -iname \*.root  -or -iname \*.log -or -iname \*.xml -type f | while read -r f; do  
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
	rm -f $f
done



