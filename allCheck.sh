#!/bin/bash 
export VDT_LOCATION=/data/vdt
export EDG_WL_LOCATION=$VDT_LOCATION/edg
source /data/vdt/setup.sh 
cmssw_release=CMSSW_3_8_6_patch1

cms2_tag=V03-06-16

dataset_name_1=`echo /Electron/Run2010B-Nov4ReReco_v1/RECO `
dataset_name_2=`echo /Mu/Run2010A-Nov4ReReco_v1/RECO `



while [ 1 ]
  do


  source checkFailedJobs.sh $dataset_name_1 $cms2_tag >& /dev/null
  source checkFailedJobs.sh $dataset_name_2 $cms2_tag >& /dev/null


  sleep 7200
done 