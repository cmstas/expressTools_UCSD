dc=$1
TOOL_DIR=$PWD
submitDir=$2
#minRun=134987
minRun=$4
maxRun=$5
cd $submitDir
# get list of files which were not linked to the grouped
#find grouped -name \*Commissioning10_MinimumBias_RECO_v9\*.root > files.grouped
[ ! -f "grouped.list" ]  && touch grouped.list
cat grouped.list |grep ".root" >files.grouped
#ls ${dc} | grep  ".root" | grep Commissioning10_MinimumBias_RECO_v9 |grep -v ".log" |while read -r f; do
ls ${dc} | grep  ".root" |grep -v ".log" |while read -r f; do
grep ${f} files.grouped >& /dev/null || echo ${f} ; done >files.ls

# copy current list (made by submitter)
cp ${submitDir}/a.runs.list.tmp runs.all.express
grep ^[1-9] runs.all.express | awk '{print $1}' | sort -g | uniq > runs.txt
cat files.ls | while read -r fr; do
    f_0=`echo $fr | cut -d"_" -f12 `
   # f=`echo "$f_0.root" `
    run=`grep  $f_0 runs.all.express | awk '{print $1}'`
    #(( run > minRun )) && echo $run $f `grep $f files.ls`
    (( run >= minRun )) && (( run <= maxRun )) && echo $run `grep $fr files.ls`
done > files.runs.ls
grep -v ^[1-9]  files.runs.ls >& /dev/null && echo Corrupt  files.runs.ls && exit 33

grep _cms files.runs.ls | cut -d" " -f1 | sort | uniq | while read -r rn; do 
    if [ ! -d "${rn}" ] ; then 
	mkdir ${rn}
	rnL=`echo ${rn} | cut -c1-3`
	rnR=`echo ${rn} | cut -c4-6`
	ls -d ${dc}/${rnL} >& /dev/null || mkdir ${dc}/${rnL} 
	mkdir ${dc}/${rnL}/${rnR}
    fi
done
grep _cms files.runs.ls | while read -r rn fr; do 
    if [ ! -h "$rn/$fr" ] ; then
	ln -s ${dc}/${fr} ${rn}/${fr}
	sleep 1
	rnL=`echo ${rn} | cut -c1-3`
        rnR=`echo ${rn} | cut -c4-6`
	fLog=`echo ${fr} | sed -e 's/.root/.log/g' `
	#rfrename ${dc}/${fr} ${dc}/${rnL}/${rnR}/${fr}
	#rfrename ${dc}/${fLog} ${dc}/${rnL}/${rnR}/${fLog}
	echo ${fr}  >>  grouped.list
    fi
done

ls newC/ | grep C$ | while read -r c; do 
    oC=oldC/${c}
    nC=newC/${c}
    if [ ! -f ${oC} ] ; then 
	echo "New file was generated last time: shouldn't happen. Do manually"
	exit 36
    fi
    echo "WARNING : ${nC} is still in the merge queue : check it. File probably missing"
#    cp ${nC} ${oC}
#    chmod a-w ${oC}
done
mrgDest=$3
ls -d 1[3-9]* | while read -r rn; do
    (( rn < minRun )) && (( rn > maxRun )) && continue
#    echo Checking $rn
    count=0 
    sec=-1
    cTot=`ls ${rn} | grep -c root`
    curCount=0
    refCount=0
    ls -tr ${rn} | grep ".root"$ | while read -r f; do
	(( cTot-- ))
	(( count++ ))
	scriptC=comb${rn}_${sec}.C; s=${scriptC}_temp
	startNew="NO" 
	(( curCount == 0 )) && startNew="YES"
	if [ "${startNew}" == "YES" ] ; then
	    (( sec++ ))
	    scriptC=comb${rn}_${sec}.C; s=${scriptC}_temp
#	    echo "Starting new ${scriptC}"
      # 
	    if [ -f "${s}" ] ; then
		echo "Old ${s} not closed. Something is wrong" 
		exit 35
	    fi
	    (( seNext=sec+1 ))
	    scriptNext=comb${rn}_${seNext}.C
	    (( sePrev=sec-1 ))
	    scriptPrev=comb${rn}_${sePrev}.C
	  # need to decide here what to do
	  # the cleanest is to start a new file; unfortunately this means small files will be present
	  # the alternatives are too complicated
	    if [ -f "oldC/${scriptC}" ] ; then
		fileFound=`grep -c ${f} oldC/${scriptC}`
		if (( fileFound == 1 ))  ; then
#			echo "Skip ${f} now ${sec}"
		    (( curCount=0 ))
		    (( refCount++ ))
#		    echo "${scriptC} refCount is ${refCount}"
		    (( sec-- )) 
		    if (( cTot == 0 )) ; then
			# this is the last time we are in this loop
			#nRef=`grep -c ".root" oldC/${scriptC}`
			nRef=`grep -v "e->Merge" oldC/${scriptC} | grep -c ".root" `
			if (( refCount != nRef )) ; then
			    echo "File mismatch at last point in ${scriptC}: ${refCount} != ${nRef} "
			    exit 40
			fi
#			cp oldC/${scriptC} newC/${scriptC}
			refCount=0
		    fi
		    continue
		else
		    (( haveNext=0 ))
		    [ -f "oldC/${scriptNext}" ] && haveNext=`grep -c ${f} oldC/${scriptNext}`
		    #nRef=`grep -c ".root" oldC/${scriptC}`
		    nRef=`grep -v "e->Merge" oldC/${scriptC} | grep -c ".root" `
		    if (( refCount != nRef )) ; then 
			echo "File mismatch at ${scriptC}  roll: ${refCount} != ${nRef}"
			exit 40
		    fi
#		    cp oldC/${scriptC} newC/${scriptC}
		    if (( haveNext==1 )) ; then
			(( curCount=0 )) 
			refCount=1
			# after this the sec should increment and naturally go to next file
			continue
		    fi
		fi
		if (( fileFound > 1 || haveNext > 1 )); then
		    echo "Something is wrong: multiple copies of $f in merge scripts"
		    exit 38
		fi
		echo "Old merge ${scriptC} present: will not remerge"
		(( sec++ ))
		scriptC=comb${rn}_${sec}.C; s=${scriptC}_temp
	    fi
	    echo "New/updated end merge ${scriptC} " 
	
	    echo -e "void comb${rn}_${sec}(){\n gSystem->Load(\"${TOOL_DIR}/libMiniFWLite.so\");\n" >> ${s}
	    echo -e "\n\tTTree::SetMaxTreeSize(39000000000);" >> ${s}
	    echo -e "\n\te = new TChain(\"Events\");\n "  >> ${s}
	fi
	echo -e "\n\te->Add(\"${rn}/${f}\");">> ${s}
	(( curCount++ ))
	closeC="NO"
	#(( curCount == 100 || cTot == 0 ))  && closeC="YES"
	(( curCount == 10 || cTot == 0 ))  && closeC="YES"
#  echo ${curCount} ${cTot} closeC ${closeC}
	if [ "${closeC}" == "YES" ] ; then
	    echo -e "\n\te->Merge(\"${mrgDest}/temp/merged_ntuple_${rn}_${sec}_ready.root\",\"fast\");\n}" >> ${s}
	    [ ! -f "oldC/${scriptC}" ] && echo "New ${scriptC} " && mv -f ${s} newC/${scriptC}
	    if [ -f "${s}" -a -f "oldC/${scriptC}" ] ; then
		isSame=`diff ${s} oldC/${scriptC} | grep -c ".root"`
		if [ "${isSame}" != "0" ] ; then 
		    echo "Override old ${scriptC} not possible" 
		    rm ${s} 
#		    cp oldC/${scriptC}  newC/${scriptC}
		    exit 37
		fi
		[ "${isSame}" == "0" ]  &&  mv -f ${s} newC/${scriptC}
	    fi
      (( curCount=0 ))
	fi
    done
done

#echo Testing only && exit 30

rm -f merge.list
touch merge.list
ls newC/*.C | while read -r  nC ;  do 
    oC=`echo ${nC} | sed -e "s?newC/?oldC/?g"` 
    [ ! -f "${oC}" ] && echo $nC >> merge.list
    if [ -f "${oC}" ] ; then 
	nDiffs=`diff $nC $oC | grep -c ".root"`
	if (( nDiffs > 0 )) ; then
	    echo "New File ${nC} overlaps with old ${oC} "
	    exit 37
	else
	    echo "Warning: $nC and $oC are both present. They're the same here. Still, shouldn't happen"
	fi
    fi
done 

cat merge.list | grep C$ | while read -r f ;  do 
    echo $f
    root -l -b -q $f
    nC=${f}
    oC=`echo ${nC} | sed -e "s?newC/?oldC/?g"`
    fDest=`grep Merge ${nC} | tr '\"' '\n' | grep _ready`
    if [ "x${fDest}" == "x" ] ; then
	echo "Corrupt ${nC}"

	exit 38

    fi
    if [ -s "${fDest}" ] ; then
	echo "all done with ${fDest} , copy $nC to $oC"
	fDGood=`echo ${fDest} | sed -e 's/_ready//g;s?/temp/?/?g'`
	mv ${fDest} ${fDGood}
	mv ${nC} ${oC}
	chmod a-w ${oC}
    fi
done >& merging_log/merging.log.`date '+\%Y.\%m.\%d-\%H.\%M.\%S'`
#now move done files to merged
find ${mrgDest}/ -name merged_ntuple\*_ready.root | while read -r f ; do
    echo ${f}
    fo=`echo $f | sed -e 's/_ready//g;s?/temp/?/failed?g'`
    mv ${f} ${fo}
done



cd $TOOL_DIR
