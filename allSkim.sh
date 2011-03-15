#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 

cmssw_release=CMSSW_4_1_2
cms2_tag=V04-00-00

dataset_names="`echo /SingleMu/Run2011A-PromptReco-v1/AOD`"




for dataset_name in $dataset_names; do
    source checkAndRunSkim.sh $cmssw_release $cms2_tag $dataset_names
done



