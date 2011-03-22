#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 

mssw_release=CMSSW_4_1_2_patch1
cms2_tag=V04-00-08



dataset_names="`echo /DoubleMu/Run2011A-PromptReco-v1/AOD` `echo /DoubleElectron/Run2011A-PromptReco-v1/AOD` `echo /MuEG/Run2011A-PromptReco-v1/AOD`"
#dataset_names="`echo /DoubleElectron/Run2011A-PromptReco-v1/AOD`"                                                                                                 



while [ 1 ]
  do
  for dataset_name in $dataset_names; do
      source checkFailedJobs.sh $dataset_name $cms2_tag >& /dev/null
  done
 
  sleep 6600
done 