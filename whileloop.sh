#!/bin/bash 
cmssw_release=$1
cms2_tag=$2
dataset_name_1=$3


cmssw_dir=`echo /code/osgcode/yanjuntu/${cmssw_release}_${cms2_tag}/src `

minRunNumber=`echo 0 `
maxRunNumber=`echo 999999 `
config_file=`echo Data386ReReco_SDFilter_cfg.py`
hadoop_dir=`echo /hadoop/cms/store/user/macneill/${cmssw_release}_${cms2_tag}`
express_tool_dir=` echo $PWD `
#out_dir=` echo /nfs-3/userdata/yanjuntu `
out_dir=`echo /nfs-4/userdata/imacneill`
[ ! -d "${hadoop_dir}" ] && echo Create ${hadoop_dir} && mkdir ${hadoop_dir}

#dataset_dir_1=`echo $dataset_name_1 |sed -e 's/\/MinimumBias/MinimumBias/g;s?/?_?g' `
dataset_dir_1_tmp=`echo $dataset_name_1 |sed -e 's?/?_?g' `
dataset_dir_1=`echo ${dataset_dir_1_tmp:1} ` 
dataset_hadoop_dir_1=`echo ${hadoop_dir}/${dataset_dir_1} `

express_tool_subdir_1=${express_tool_dir}/${dataset_dir_1}
[ ! -d "${express_tool_subdir_1}" ] && echo Create ${express_tool_subdir_1} && mkdir ${express_tool_subdir_1}
[ ! -f "${express_tool_subdir_1}/a.list" ]  && echo Create ${express_tool_subdir_1}/a.list && touch ${express_tool_subdir_1}/a.list
#[ ! -d "${express_tool_subdir_1}/grouped" ] && echo Create ${express_tool_subdir_1}/grouped && mkdir ${express_tool_subdir_1}/grouped
[ ! -d "${express_tool_subdir_1}/newC" ] && echo Create ${express_tool_subdir_1}/newC && mkdir ${express_tool_subdir_1}/newC
[ ! -d "${express_tool_subdir_1}/oldC" ] && echo Create ${express_tool_subdir_1}/oldC && mkdir ${express_tool_subdir_1}/oldC
[ ! -d "${express_tool_subdir_1}/output" ] && echo Create ${express_tool_subdir_1}/output && mkdir ${express_tool_subdir_1}/output
[ ! -d "${express_tool_subdir_1}/submitting_log" ] && echo Create ${express_tool_subdir_1}/submitting_log && mkdir ${express_tool_subdir_1}/submitting_log
[ ! -d "${express_tool_subdir_1}/merging_log" ] && echo Create ${express_tool_subdir_1}/merging_log && mkdir ${express_tool_subdir_1}/merging_log
[ ! -d "${dataset_hadoop_dir_1}" ] && echo Create ${dataset_hadoop_dir_1} && mkdir ${dataset_hadoop_dir_1}
unmerged_file_dir_1=`echo ${dataset_hadoop_dir_1}/${cmssw_release}_${cms2_tag} `
merged_file_dir_1=`echo $out_dir/${dataset_dir_1}/${cms2_tag} `
[ ! -d "$out_dir/${dataset_dir_1}" ] && echo Create  $out_dir/${dataset_dir_1} && mkdir $out_dir/${dataset_dir_1}
[ ! -d "$out_dir/${dataset_dir_1}/${cms2_tag}" ] && echo Create $out_dir/${dataset_dir_1}/${cms2_tag} && mkdir $out_dir/${dataset_dir_1}/${cms2_tag}
[ ! -d "$out_dir/${dataset_dir_1}/${cms2_tag}/temp" ] && echo Create $out_dir/${dataset_dir_1}/${cms2_tag}/temp && mkdir $out_dir/${dataset_dir_1}/${cms2_tag}/temp

while [ 1 ]
  do
  

  source checkAndSubmit.sh $cmssw_dir $dataset_name_1 $dataset_dir_1 $minRunNumber $dataset_hadoop_dir_1 $config_file $cms2_tag $maxRunNumber $4 $5
  sleep 5400

  source checkAndMerge.sh $unmerged_file_dir_1 $express_tool_subdir_1  $merged_file_dir_1 ${minRunNumber} $maxRunNumber $4 $5
  sleep 5400
done

