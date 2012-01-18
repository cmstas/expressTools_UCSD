#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 

echo "allSkim.sh PID is $$"

ConfigFiles=$@

#while [1]; do

	for Config in $ConfigFiles; do
		source checkAndRunSkim.sh $Config

	done
#	sleep 7200
#done


# #### USER SET VARIABLE ####
# cmssw_release=CMSSW_4_2_4
# cms2_tag=V04-02-22
# dataset_names="/Photon/Run2011A-PromptReco-v4/AOD /MuEG/Run2011A-May10ReReco-v1/AOD /TTWTo2Lminus2Nu_7TeV-madgraph/Summer11-PU_S4_START42_V11-v1/AODSIM"


# echo "allSkim.sh PID is $$"

# #while [ 1 ]                                                                                                                                  
# #  do 

#   for dataset_name in $dataset_names; do
#     source checkAndRunSkim.sh $cmssw_release $cms2_tag $dataset_name
#   done
# #  sleep 7200 
# #done


