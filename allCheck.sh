#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 


ConfigFiles=$@

for Config in $ConfigFiles; do
    source checkFailedJobs.sh $Config &
	echo "checkFailedJobs.sh PID is $$"
done


# #### USER SET VARIABLES ####
# CMSSWRelease=CMSSW_4_2_4
# CMS2Tag=V04-02-22
# who=macneill


# dataset_names="/Photon/Run2011A-PromptReco-v4/AOD /MuEG/Run2011A-May10ReReco-v1/AOD /TTWTo2Lminus2Nu_7TeV-madgraph/Summer11-PU_S4_START42_V11-v1/AODSIM"

 
# echo "allCheck.sh PID is $$"
 
# #while [ 1 ]
# #  do
#   for dataset_name in $dataset_names; do
#       source checkFailedJobs.sh $dataset_name $CMS2Tag $CMSSWRelease $who &
# 	  echo "checkFailedJobs.sh PID is $$"
#   done
 
# #  sleep 6600
# #done 