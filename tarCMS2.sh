#! /bin/bash

: ${1?"No specified CMSSW Release and location (arg 1). Exiting"}
: ${2?"No specified location to move the tarred NtupleMaker Code (arg2). Exiting"}
: ${3?"No specified SCRAM_ARCH (arg 3). Exiting"}

LONGCMSSW=$1
SHORTCMSSW=${LONGCMSSW##*/}
OUTLOCATION=$2
export SCRAM_ARCH=$3

if [ ! -d "$LONGCMSSW" ]; then
	echo "Error. Cannot find specified CMSSW release, $LONGCMSSW."
	exit 1
fi

if [ ! -d "${LONGCMSSW}/src/CMS2" ]; then
	echo "Error. Cannot find CMS2 in specified location, ${LONGCMSSW}/src/CMS2"
	exit 1
fi

if [ ! -d "$OUTLOCATION" ]; then
	echo "Error. Cannad find location to put the tarred NtupleMaker, $OUTLOCATION"
	exit 1
fi

echo "Don't know if the CMS2 release is built. Will cd into the release area, set CMSSW environment, and run scram to be safe."
cd $LONGCMSSW
eval `scram runtime -sh`
scramv1 b -j 25
ERROR=$?
if [ "$ERROR" != 0 ]; then
	echo "Error building CMS2. Exiting."
	exit $ERROR
fi


echo "Tarring the file now."
tar -cvz --exclude NtupleMacros -f ${SHORTCMSSW}.tgz *

ERROR=$?

if [ "$ERROR" != 0 ]; then
	"Error tarring, $LONGCMSSW. Exiting"
	exit $ERROR
fi

cd -
mv ${LONGCMSSW}/${SHORTCMSSW}.tgz ${OUTLOCATION}

exit 0