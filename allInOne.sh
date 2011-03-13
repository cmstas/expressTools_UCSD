#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 
fileFormat="`echo prompt` "
who=yanjuntu



cmssw_release=CMSSW_3_8_6_patch1
cms2_tag=V03-06-16


#dataset_names="`echo /Electron/Run2010B-Nov4ReReco_v1/RECO` `echo /Mu/Run2010A-Nov4ReReco_v1/RECO`"
dataset_names="`echo /Electron/Run2010B-PromptReco-v2/RECO` "




for dataset_name in $dataset_names; do
    source whileloop.sh $cmssw_release $cms2_tag $dataset_name $fileFormat $who &
done







