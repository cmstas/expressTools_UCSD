cmssw_release=$1
cms2_tag=$2
dataset_name=$3
merged_dir=` echo /nfs-3/userdata/cms2 `
dataset_dir_tmp=`echo $dataset_name |sed -e 's?/?_?g' `
dataset_dir=`echo ${dataset_dir_tmp:1} `
merged_file_dir=`echo $merged_dir/${dataset_dir}/${cms2_tag} `
#out_dir=` echo /nfs-3/userdata/cms2/$dataset_dir `
#out_dir_0=` echo /nfs-3/userdata/yanjuntu/Prompt_Data_${cmssw_release}_${cms2_tag} `
#out_dir=` echo ${out_dir_0}/$dataset_dir `
out_dir=` echo $merged_file_dir ` 
skim_dir=` echo singleLepPt10Skim `
#skim_dir_2=` echo pfJetPt30Skim `
skim_dir_3=` echo diLepPt1020Skim `
#[ ! -d "$out_dir_0" ] && echo Create  $out_dir_0 && mkdir $out_dir_0
[ ! -d "$out_dir" ] && echo Create  $out_dir && mkdir $out_dir
[ ! -d "$merged_file_dir" ] && echo Create $merged_file_dir && mkdir $merged_file_dir
#[ ! -d "$out_dir/${skim_dir}" ] && echo Create  $out_dir/${skim_dir} && mkdir $out_dir/${skim_dir}
#[ ! -d "$out_dir/${skim_dir}/log" ] && echo Create  $out_dir/${skim_dir}/log && mkdir $out_dir/${skim_dir}/log
#[ ! -f "$out_dir/${skim_dir}/README" ] && echo Create  $out_dir/${skim_dir}/README && touch $out_dir/${skim_dir}/README
#if [ ! -f "$out_dir/${skim_dir}/README" ] ; then
#echo -e "run number > 142600  ">> $out_dir/${skim_dir}/README 
#echo -e "root -l -b -q \"makeSkim.C(\"${f}\",\"${fO}_ready\",\"(Sum\$(mus_p4.pt()>10)+Sum\$(els_p4.pt()>10))>0\")\" " >> $out_dir/${skim_dir}/README 
#echo -e "root -l -b -q \"makeSkim.C(\"${f}\",\"${fO}_ready\",\"(Sum\$(mus_p4.pt()>10)+Sum\$(els_p4.pt()>10 || els_eSC/cosh(els_etaSC)>10))>0\")\" " >> $out_dir/${skim_dir}/README 
#fi
[ ! -d "$out_dir/skim_log" ] && echo Create  $out_dir/skim_log && mkdir $out_dir/skim_log
#[ ! -d "$out_dir/${skim_dir_2}" ] && echo Create  $out_dir/${skim_dir_2} && mkdir $out_dir/${skim_dir_2}
#if [ ! -f "$out_dir/${skim_dir_2}/README" ] ; then
#echo -e "root -l -b -q \"makeSkim.C(\"${f}\",\"${fO}_ready\",\"Sum\$(pfjets_p4.pt()>30)>0\")\" " >> $out_dir/${skim_dir_2}/README 
#fi
[ ! -d "$out_dir/${skim_dir_3}" ] && echo Create  $out_dir/${skim_dir_3} && mkdir $out_dir/${skim_dir_3}
if [ ! -f "$out_dir/${skim_dir_3}/README" ] ; then
#echo -e "run number > 142600 ">> $out_dir/${skim_dir_3}/README
echo -e "root -l -b -q \"makeSkim.C(\"${f}\",\"${fO}_ready\",\"(Sum\$(mus_p4.pt()>10)+Sum\$(els_p4.pt()>10 || els_eSC/cosh(els_etaSC)>10))>1 && (Sum\$(mus_p4.pt()>20)+Sum\$(els_p4.pt()>20 || els_eSC/cosh(els_etaSC)>20 ))>0\")\" " >> $out_dir/${skim_dir_3}/README
fi

echo "Start skims at "`date`
dateS=`date '+%Y.%m.%d-%H.%M.%S'`
ext=singleLepPt10; 
#ext_2=pfJetPt30;
ext_3=diLepPt1020Skim
for di in ${merged_file_dir}; do
    #count=0
    find ${di} -name merged_ntuple_\*.root | while read -r f; do
	echo "                             "
	echo "Start  dilepton skimming "
        echo "                             "
        fO_3=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir_3}/skimmed?g" `
	[ ! -f "${fO_3}" -o "${f}" -nt ${fO_3} ]   && echo ${fO_3} &&\
	    root -l -b -q "makeSkim.C(\"${f}\",\"${fO_3}_ready\",\"(Sum\$(mus_p4.pt()>10)+Sum\$(els_p4.pt()>10 || els_eSC/cosh(els_etaSC)>10))>1 && (Sum\$(mus_p4.pt()>20)+Sum\$(els_p4.pt()>20 || els_eSC/cosh(els_etaSC)>20))>0\")"
	[ -f "${fO_3}_ready" ] && echo ${fO_3}_ready && mv -f ${fO_3}_ready ${fO_3}
	#echo "                             "
	#echo "Start single lepton skimming "
	#echo "                             "
       	#fO=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir}/skimmed?g" `
      	#[ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} &&\
	 #   root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"(Sum\$(mus_p4.pt()>10)+Sum\$(els_p4.pt()>10 || els_eSC/cosh(els_etaSC)>10))>0\")"  
	#[ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
	
        #echo "                     "
	#echo "Start pfjet skimming "
	#echo "                     "
	#fO_2=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir_2}/skimmed?g" `
       	#[ ! -f "${fO_2}" -o "${f}" -nt ${fO_2} ]   && echo ${fO_2} &&\
	 #   root -l -b -q "makeSkim.C(\"${f}\",\"${fO_2}_ready\",\"Sum\$(pfjets_p4.pt()>30)>0\")"  
	#[ -f "${fO_2}_ready" ] && echo ${fO_2}_ready && mv -f ${fO_2}_ready ${fO_2} 
    done 
#done   >&  $out_dir/${skim_dir}/log/${ext}Skim.log.${dateS}
done   >&  $out_dir/skim_log/Skim.log.${dateS}

echo "Done skimming "`date`

#echo "Start pfjet skims at "`date`
#dateS=`date '+%Y.%m.%d-%H.%M.%S'`
#ext=pfJetPt30; for di in ${merged_file_dir}; do
    #count=0
#    find ${di} -name merged_ntuple_\*.root | while read -r f; do
 #      	fO=`echo ${f} | sed -e "s?${merged_file_dir}/merged?${out_dir}/${skim_dir_2}/skimmed?g" `
        #	[ ! -f "${fO}" -o "${f}" -nt ${fO} ] && (( count++ )) && (( count<25 )) && echo ${fO} &&\
        #	[ ! -f "${fO}" -o "${f}" -nt ${fO} ] && (( count++ ))  && echo ${fO} &&\
	#[ ! -f "${fO}" -o "${f}" -nt ${fO} ]   && echo ${fO} &&\
	 #   root -l -b -q "makeSkim.C(\"${f}\",\"${fO}_ready\",\"Sum\$(pfjets_p4.pt()>30)>0\")"
	#[ -f "${fO}_ready" ] && echo ${fO}_ready && mv -f ${fO}_ready ${fO}
    #done 
#done >&  $out_dir/${skim_dir_2}/log/${ext}Skim.log.${dateS}

#echo "Done pfjet skimming "`date`