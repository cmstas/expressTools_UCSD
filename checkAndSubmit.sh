#!/bin/bash
dir_gw2=$1
sd_dataset_name=$2
sd_sub_dir=$3
min_run=$4
output_dir=$5
config_file=$6
cms2_tag=$7
max_run=$8
TOOL_DIR=./
fileFormat=$9

python getLFNList_reco.py --dataset=${sd_dataset_name}|grep .root  > ${sd_sub_dir}/a.runs.list.tmp.phedex
dbsql "find run, file where file.status=VALID and dataset=$sd_dataset_name and  run >=${min_run} and run <=${max_run} " |grep store/ >  ${sd_sub_dir}/a.list.dbs

if [ -s "${sd_sub_dir}/a.list.dbs" ] ; then
     if [ -s "${sd_sub_dir}/a.runs.list.tmp.phedex" ]; then 
         #cat ${sd_sub_dir}/a.runs.list.tmp.phedex|grep .root|awk '{print $2}' | while read -r f; do
	 cat ${sd_sub_dir}/a.list.dbs|grep .root | while read -r rn f; do
             grep $f  ${sd_sub_dir}/a.runs.list.tmp.phedex>& /dev/null && echo $rn $f  
         done  &> ${sd_sub_dir}/a.runs.list.tmp 
     fi 
else
    echo a.list.dbs is empty   
    which mail >& /dev/null && mail -s "dbs query fails " yanjuntu@ucsd.edu < ${sd_sub_dir}/a.list.dbs.tmp 
    exit 99
fi


#cat ${sd_sub_dir}/a.runs.list.tmp |awk '{print $2}' > ${sd_sub_dir}/a.runs.list0.tmp
cat ${sd_sub_dir}/a.runs.list.tmp |grep .root > ${sd_sub_dir}/a.runs.list0.tmp

'cp' ${sd_sub_dir}/a.list ${sd_sub_dir}/a.list.old
'cp' ${sd_sub_dir}/a.runs.list0.tmp ${sd_sub_dir}/a.list


#now we have the old list and the new full list. 
#The next is to get the list of new files (assumes old files were sent for processing, if not the recovery to be done manually)
#check for empty output
aSize=`grep store/ ${sd_sub_dir}/a.list | grep -c root`
[ "${aSize}" == "0" ] && echo "Failed to get file list" && exit 23
#'rm' -f ${sd_sub_dir}/a.list.new; touch ${sd_sub_dir}/a.list.new; grep store ${sd_sub_dir}/a.list | while read -r f; do grep $f ${sd_sub_dir}/a.list.old >& /dev/null || echo $f >> ${sd_sub_dir}/a.list.new; done
'rm' -f ${sd_sub_dir}/a.list.new; touch ${sd_sub_dir}/a.list.new; grep store ${sd_sub_dir}/a.list | while read -r rn f; do grep $f ${sd_sub_dir}/a.list.old >& /dev/null || echo $rn $f >> ${sd_sub_dir}/a.list.new; done
aNewSize=`grep -c store ${sd_sub_dir}/a.list.new`
#Don't submit too many jobs, change 2000 below to smth you think make sense
#(( aNewSize>2000 )) && echo "Need to sub ${aNewSize} jobs: Too many jobs to submit, do it manually " && exit 24
echo "Will submit ${aNewSize} files"

# now let's decide where this goes
#get the jobstatus into a text file
#bjobs -w > bjobs.last

nToSub=`grep -c store ${sd_sub_dir}/a.list.new `

if (( nToSub > 0 )) ; then
    dateS=`date '+%Y.%m.%d-%H.%M.%S'`
    subLog=sub.log.${dateS}
    grep store ${sd_sub_dir}/a.list.new | while read -r rn f; do 
	release_dir=`echo $dir_gw2 `
	input_data=`echo root://xrootd.unl.edu/$f `
	#extention=`echo v0 `
	input_data_run=`echo $rn`
	
	#the run script takes arguments: baseReleaseDirectory configFile inputFile extensionToOutputFile
	#the output file will be a legal version of the inputFile name with : and / replaced by _ (see the script)

cat > expressTools_UCSD_${sd_sub_dir}.cmd <<@EOF
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
log    = /tmp/uselesslog-yanjuntu_${sd_sub_dir}.log
Notification = Never 
+Owner = undefined 
	
arguments=$release_dir $config_file $input_data $output_dir $sd_dataset_name $cms2_tag $input_data_run $fileFormat
output = ./${sd_sub_dir}/output/1e.\$(Cluster).\$(Process).out
error  = ./${sd_sub_dir}/output/1e.\$(Cluster).\$(Process).err
queue
	
@EOF
	
condor_submit expressTools_UCSD_${sd_sub_dir}.cmd 
    done >& $PWD/${sd_sub_dir}/submitting_log/${subLog}
    curT=`date +%s`
   
fi

echo "Done submitting. Sleep now ... "
