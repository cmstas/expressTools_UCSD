#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 
fileFormat="`echo prompt` "




cmssw_release=CMSSW_4_1_2_patch1
cms2_tag=V04-00-05


#dataset_names="`echo /Electron/Run2010B-Nov4ReReco_v1/RECO` `echo /Mu/Run2010A-Nov4ReReco_v1/RECO`"
dataset_names="`echo /DoubleElectron/Run2011A-PromptReco-v1/AOD` `echo /DoubleMu/Run2011A-PromptReco-v1/AOD` `echo /MuEG/Run2011A-PromptReco-v1/AOD`"




for dataset_name in $dataset_names; do
    source whileloop.sh $cmssw_release $cms2_tag $dataset_name $fileFormat $who &
done







