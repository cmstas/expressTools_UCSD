
dataset_name=$1
cms2_tag=$2
dataset_dir_tmp=`echo $dataset_name |sed -e 's?/?_?g' `
dataset_dir=`echo ${dataset_dir_tmp:1} ` 
log_dir=`echo ~/public_html/prompt_ntuple_log `
hadoop_dir=`echo /hadoop/cms/phedex `
cd ${dataset_dir}

#cat a.list |awk '{print $2}' |sed 's/\//\_/g' | sed 's/^/hadoop\_cms\_phedex/' > submit.list

#cat a.list  |sed 's/\//\_/g' | sed 's/^/hadoop\_cms\_phedex/' > submit.list
cat a.list  > submit.list
#cat grouped.list |  cut -d"_" -f1-12 | sed 's/$/.root/'>  grouped.list.tmp 
cat grouped.list |sed 's?_?/?g' |sed 's?store?/store?g'>  grouped.list.tmp
cat submit.list | while read -r rn f; do
    #grep ${f} grouped.list.tmp >& /dev/null || echo ${rn} ${f} | sed 's?hadoop_cms_phedex??' |sed 's?_?/?g' |sed -e 's?Nov4ReReco\/v1?Nov4ReReco_v1?g '; 
    grep ${f} grouped.list.tmp >& /dev/null || echo ${rn} ${f} ; 
#done >& failed.list
done >& $log_dir/${dataset_dir}_missing_files

cat $log_dir/${dataset_dir}_missing_files| while read -r rn f; do
f_hadoop=`echo $hadoop_dir$f `

if test `find "$f_hadoop" -mmin +1200`
    then
    echo $rn $f
fi
done >& $log_dir/${dataset_dir}_missing_files_20h

[ ! -d "$log_dir/error" ] && mkdir $log_dir/error


echo $dataset_name
wc -l submit.list
echo submitting Error or not finished jobs 
#cat failed.list
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
