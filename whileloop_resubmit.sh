#!/bin/bash 
cmssw_release=$1
cms2_tag=$2
dataset_name_1=$3

cmssw_dir=`echo /code/osgcode/yanjuntu/${cmssw_release}_${cms2_tag}/src `
minRunNumber=`echo 0 `
maxRunNumber=`echo 999999 `
config_file=`echo Data386ReReco_SDFilter_cfg.py `
hadoop_dir=` echo /hadoop/cms/store/user/yanjuntu/${cmssw_release}_${cms2_tag}` 
#express_tool_dir=` echo /home/users/yanjuntu/CMS/expressTools_UCSD `
express_tool_dir=` echo $PWD `
out_dir=` echo /nfs-3/userdata/cms2 `


dataset_dir_1_tmp=`echo $dataset_name_1 |sed -e 's?/?_?g' `
dataset_dir_1=`echo ${dataset_dir_1_tmp:1} ` 
dataset_hadoop_dir_1=`echo ${hadoop_dir}/${dataset_dir_1} `

express_tool_subdir_1=${express_tool_dir}/${dataset_dir_1}
source checkAndReSubmit.sh $cmssw_dir $dataset_name_1 $dataset_dir_1 $minRunNumber $dataset_hadoop_dir_1 $config_file $cms2_tag $maxRunNumber $4 $5

