cmssw_release=$1
cms2_tag=$2
dataset_name=$3
#merged_dir=` echo /nfs-3/userdata/cms2 `
merged_dir=` echo /hadoop/cms/store/user/yanjuntu/CMSSW_4_2_4_V04-02-20 ` #change
dataset_dir_tmp=`echo $dataset_name |sed -e 's?/?_?g' `
dataset_dir=`echo ${dataset_dir_tmp:1} `
merged_file_dir=`echo $merged_dir/${dataset_dir}/CMSSW_4_2_4_V04-02-20_merged/${cms2_tag} ` #change


out_dir_0=` echo /nfs-4/userdata/cms2/${dataset_dir} ` 
out_dir=` echo ${out_dir_0}/${cms2_tag} ` 
skim_dir=` echo tagAndProbeSkim `
skim_dir_1=` echo DoubleElectronTriggerSkim `
skim_dir_2=` echo DoubleMuTriggerSkim `
skim_dir_4=` echo SSignSkim `
skim_dir_3=` echo DilepPt2010Skim `
[ ! -d "$out_dir_0" ] && echo Create  $out_dir_0 && mkdir $out_dir_0
[ ! -d "$out_dir" ] && echo Create  $out_dir && mkdir $out_dir
[ ! -d "$out_dir/$skim_dir" ] && echo Create  $out_dir/$skim_dir && mkdir $out_dir/$skim_dir
[ ! -d "$out_dir/$skim_dir/skim_log" ] && echo Create  $out_dir/$skim_dir/skim_log && mkdir $out_dir/$skim_dir/skim_log
[ ! -d "$out_dir/$skim_dir_4/skim_log" ] && echo Create $out_dir/$skim_dir_3/skim_log && mkdir -p $out_dir/$skim_dir_4/skim_log 


echo "Start skims at "`date`
dateS=`date '+%Y.%m.%d-%H.%M.%S'`
for di in ${merged_file_dir}; do
    find ${di} -name merged_ntuple_\*.root | while read -r f; do
        echo "                             "
        echo "Start SSign skimming "
        echo "                             "
        fO=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir_4}/skimmed?g" `
        [ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} && root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"SSign\")"
        [ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
    done
done   >&  $out_dir/$skim_dir_4/skim_log/Skim.log.${dateS}

for di in ${merged_file_dir}; do
    find ${di} -name merged_ntuple_\*.root | while read -r f; do
	echo "                             "
	echo "Start  tag and probe skimming "
        echo "                             "
        fO=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir}/skimmed?g" `
	[ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} && root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"tagAndProb\")"
	[ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
    done 
done   >&  $out_dir/$skim_dir/skim_log/Skim.log.${dateS}

echo "Done skimming "`date`


if [ ${dataset_name} == "/SingleMu/Run2011A-May10ReReco-v1/AOD" ]; then
    [ ! -d "$out_dir/$skim_dir_3" ] && echo Create  $out_dir/$skim_dir_3 && mkdir $out_dir/$skim_dir_3
    [ ! -d "$out_dir/$skim_dir_3/skim_log" ] && echo Create  $out_dir/$skim_dir_3/skim_log && mkdir $out_dir/$skim_dir_3/skim_log
    if [ ! -f "$out_dir/${skim_dir_3}/README" ] ; then
        echo -e DilepPt2010
    fi
    for di in ${merged_file_dir}; do
        find ${di} -name merged_ntuple_\*.root | while read -r f; do
            echo "                             "
            echo "Start  tag and probe skimming "
            echo "                             "
            fO=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir_3}/skimmed?g" `
            [ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} && root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"SingleMu\")"
            [ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
        done
    done   >&  $out_dir/$skim_dir_3/skim_log/Skim.log.${dateS}

fi