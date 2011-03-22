cmssw_release=$1
cms2_tag=$2
dataset_name=$3
#merged_dir=` echo /nfs-3/userdata/cms2 `
merged_dir=` echo /hadoop/cms/store/user/yanjuntu/CMSSW_4_1_2_patch1_V04-00-08 ` #change
dataset_dir_tmp=`echo $dataset_name |sed -e 's?/?_?g' `
dataset_dir=`echo ${dataset_dir_tmp:1} `
merged_file_dir=`echo $merged_dir/${dataset_dir}/CMSSW_4_1_2_patch1_V04-00-08_merged/${cms2_tag} ` #change

out_dir_0=` echo /nfs-4/userdata/cms2/${dataset_dir} ` 
out_dir=` echo ${out_dir_0}/${cms2_tag} ` 
skim_dir=` echo tagAndProbeSkim `
[ ! -d "$out_dir_0" ] && echo Create  $out_dir_0 && mkdir $out_dir_0
[ ! -d "$out_dir" ] && echo Create  $out_dir && mkdir $out_dir
[ ! -d "$out_dir/$skim_dir" ] && echo Create  $out_dir/$skim_dir && mkdir $out_dir/$skim_dir
[ ! -d "$out_dir/$skim_dir/skim_log" ] && echo Create  $out_dir/$skim_dir/skim_log && mkdir $out_dir/$skim_dir/skim_log
if [ ! -f "$out_dir/${skim_dir}/README" ] ; then
echo -e tag and probe skim
fi

echo "Start skims at "`date`
dateS=`date '+%Y.%m.%d-%H.%M.%S'`

for di in ${merged_file_dir}; do
    find ${di} -name merged_ntuple_\*.root | while read -r f; do
	echo "                             "
	echo "Start  tag and probe skimming "
        echo "                             "
        fO=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir}/skimmed?g" `
	[ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} && root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"tagAndProb\")"
	    #root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"(Sum\$(mus_p4.pt()>10)+Sum\$(els_p4.pt()>10 || els_eSC/cosh(els_etaSC)>10))>1 && (Sum\$(mus_p4.pt()>20)+Sum\$(els_p4.pt()>20 || els_eSC/cosh(els_etaSC)>20))>0\")"
	[ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
    done 
done   >&  $out_dir/$skim_dir/skim_log/Skim.log.${dateS}

echo "Done skimming "`date`

