cur_dir=$PWD
dataset_name=$1
cms2_tag=$2
dataset_dir_tmp=`echo $dataset_name |sed -e 's?/?_?g' `
dataset_dir=`echo ${dataset_dir_tmp:1} ` 
log_dir=`echo /home/users/yanjuntu/public_html/prompt_ntuple_log `
hadoop_dir=`echo /hadoop/cms/phedex `
cd ${dataset_dir}

cat a.list  > submit.list
cat grouped.list |sed 's?_?/?g' |sed 's?store?/store?g'>  grouped.list.tmp
cat submit.list | while read -r rn f; do
    grep ${f} grouped.list.tmp >& /dev/null || echo ${rn} ${f} ; 
done >& $log_dir/${dataset_dir}_missing_files

cat $log_dir/${dataset_dir}_missing_files| while read -r rn f; do
f_hadoop=`echo $hadoop_dir$f `

if [ ! -s "$f_hadoop" ]; then
    echo $rn $f
elif test `find "$f_hadoop" -mmin +1200`; then
    echo $rn $f
fi
done >& $log_dir/${dataset_dir}_missing_files_20h

[ ! -f "a.list.resubmit" ]  && echo Create a.list.resubmit && touch a.list.resubmit
cat $log_dir/${dataset_dir}_missing_files_20h |grep .root > a.runs.list0.tmp.resubmit
'cp' a.list.resubmit a.list.old.resubmit
'cp' a.runs.list0.tmp.resubmit a.list.resubmit
'rm' -f a.list.new.resubmit; touch a.list.new.resubmit; grep store a.list.resubmit | while read -r rn f; do grep $f a.list.old.resubmit >& /dev/null || echo $rn $f >> a.list.new.resubmit; done
aNewSize=`grep -c store a.list.new.resubmit`
echo "Will resubmit ${aNewSize} files"
cat a.list.new.resubmit
nToSub=`grep -c store a.list.new.resubmit `
if (( nToSub > 0 )) ; then
    dateS=`date '+%Y.%m.%d-%H.%M.%S'`
    subLog=sub.log.${dateS}
    'cp' ../expressTools_UCSD_${dataset_dir}.cmd expressTools_UCSD_${dataset_dir}_resubmit.cmd
    grep store a.list.new.resubmit | while read -r rn f; do 
	input_data=`echo root://xrootd.unl.edu/$f `
	python ../resubmit.py expressTools_UCSD_${dataset_dir}_resubmit.cmd ${input_data}
	echo ${input_data}
	cd ${cur_dir}
	condor_submit ${dataset_dir}/expressTools_UCSD_${dataset_dir}_resubmit.cmd
	cd ${cur_dir}/${dataset_dir}
    done >& submitting_log/${subLog}
fi

[ ! -d "$log_dir/error" ] && mkdir $log_dir/error
chmod 777 $log_dir/error

echo $dataset_name
wc -l submit.list
echo submitting Error or not finished jobs 
cat $log_dir/${dataset_dir}_missing_files
echo merge Error
ls -d merging_log/merging*| while read -r f; do
     cat ${f} |grep "Error"
done | uniq >&$log_dir/error/${dataset_dir}_merging_error 

cat grouped.list |grep .root | while read -r f; do
    grep $f oldC/*.C >& /dev/null || echo "$f is not in merge";
done >& ${log_dir}/mismerging/${dataset_dir}_mismerging

cd ../

echo skim Error
[ -d "/nfs-4/userdata/cms2/$dataset_dir/$cms2_tag/skim_log" ] && ls -d /nfs-4/userdata/cms2/$dataset_dir/$cms2_tag/skim_log/*log* |while read -r f; do
    cat ${f}|grep "Error"
done | uniq >&$log_dir/error/${dataset_dir}_skimming_error
[ ! -d "/nfs-4/userdata/cms2/$dataset_dir/$cms2_tag/skim_log" ] && echo did no find skim log
