#!/bin/bash
dir_gw2=$1
sd_dataset_name=$2
sd_sub_dir=` echo $3/resubmit `
min_run=$4
output_dir=$5
config_file=$6
cms2_tag=$7
max_run=$8
TOOL_DIR=./
whereAmI=$9
fileFormat=$10
[ ! -d "$sd_sub_dir" ] && echo Create $sd_sub_dir && mkdir $sd_sub_dir
[ ! -d "$sd_sub_dir/submitting_log" ] && echo Create $sd_sub_dir/submitting_log && mkdir $sd_sub_dir/submitting_log
[ ! -d "$sd_sub_dir/output" ] && echo Create $sd_sub_dir/output && mkdir $sd_sub_dir/output
[ ! -f "${sd_sub_dir}/a.runs.list.tmp.re" ] && echo Create ${sd_sub_dir}/a.runs.list.tmp.re && touch ${sd_sub_dir}/a.runs.list.tmp.re
#cat ${sd_sub_dir}/a.runs.list.tmp.re |awk '{print $2}' > ${sd_sub_dir}/a.runs.list0.tmp.re
cat ${sd_sub_dir}/a.runs.list.tmp.re  > ${sd_sub_dir}/a.runs.list0.tmp.re

cp ${sd_sub_dir}/a.list.re ${sd_sub_dir}/a.list.old.re
cp ${sd_sub_dir}/a.runs.list0.tmp.re ${sd_sub_dir}/a.list.re


#now we have the old list and the new full list. 
#The next is to get the list of new files (assumes old files were sent for processing, if not the recovery to be done manually)
#check for empty output
aSize=`grep store/ ${sd_sub_dir}/a.list.re | grep -c root`
[ "${aSize}" == "0" ] && echo "Failed to get file list" && exit 23
rm -f ${sd_sub_dir}/a.list.new.re; touch ${sd_sub_dir}/a.list.new.re; grep store ${sd_sub_dir}/a.list.re | while read -r rn f; do grep $f ${sd_sub_dir}/a.list.old.re >& /dev/null ||\
 echo $rn $f >> ${sd_sub_dir}/a.list.new.re; done
#rm -f ${sd_sub_dir}/a.list.new.re; touch ${sd_sub_dir}/a.list.new.re; grep store ${sd_sub_dir}/a.list.re | while read -r f; do grep $f ${sd_sub_dir}/a.list.old.re >& /dev/null || echo $f >> ${sd_sub_dir}/a.list.new.re; done
aNewSize=`grep -c store ${sd_sub_dir}/a.list.new.re`
#Don't submit too many jobs, change 2000 below to smth you think make sense
#(( aNewSize>2000 )) && echo "Need to sub ${aNewSize} jobs: Too many jobs to submit, do it manually " && exit 24
echo "Will submit ${aNewSize} files"

# now let's decide where this goes
#get the jobstatus into a text file
#bjobs -w > bjobs.last

nToSub=`grep -c store ${sd_sub_dir}/a.list.new.re `

if (( nToSub > 0 )) ; then
    dateS=`date '+%Y.%m.%d-%H.%M.%S'`
    subLog=sub.log.${dateS}
    grep store ${sd_sub_dir}/a.list.new.re | while read -r rn f; do 
	release_dir=`echo $dir_gw2 `
	input_data=`echo file:/hadoop/cms/phedex$f `
	#extention=`echo v0 `
	input_data_run=`echo $rn`
	#the run script takes arguments: baseReleaseDirectory configFile inputFile extensionToOutputFile
	#the output file will be a legal version of the inputFile name with : and / replaced by _ (see the script)

cat > ${sd_sub_dir}/expressTools_UCSD_resubmit.cmd <<@EOF
universe=grid
Grid_Resource=gt2 osg-gw-4.t2.ucsd.edu:/jobmanager-condor
executable=$PWD/runFromOneCfg_noEvCheck.sh
stream_output = False
stream_error  = False
WhenToTransferOutput = ON_EXIT
#the actual executable to run is not transfered by its name.
#In fact, some sites mya do weird things like renaming it and such.
#transfer_input_files = /home/users/yanjuntu/CMS/condor/job.sh
transfer_input_files = $PWD/${config_file}
transfer_Output_files = 
log    = /tmp/uselesslog-yanjuntu_resubmit.log
Notification = Never 
+Owner = undefined 
	
arguments=$release_dir $config_file $input_data $output_dir $sd_dataset_name $cms2_tag $input_data_run $whereAmI $fileFormat
output = ./${sd_sub_dir}/output/1e.\$(Cluster).\$(Process).out
error  = ./${sd_sub_dir}/output/1e.\$(Cluster).\$(Process).err
queue
	
@EOF
	
condor_submit ${sd_sub_dir}/expressTools_UCSD_resubmit.cmd 
    done >& $PWD/${sd_sub_dir}/submitting_log/${subLog}
    curT=`date +%s`
   
fi

echo "Done submitting. Sleep now ... "
