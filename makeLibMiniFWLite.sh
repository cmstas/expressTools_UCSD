#! /bin/bash

: ${1?"No specified CMSSW Release and location (arg 1). Exiting"}
: ${2?"No specified location into which to move the libminifwlite (arg2). Exiting"}
: ${3?"No specified SCRAM_ARCH (arg3). Exiting"}

LONGCMSSW=$1
SHORTCMSSW=${LONGCMSSW##*/}
OUTLOCATION=$2

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


cd ${LONGCMSSW}/src/CMS2/NtupleMacros/Tools/MiniFWLite
SCRAM_ARCH=$3
eval `scram runtime -sh` #make depends on the root version to make code that has root includes
make

ERROR=$?
if [ "$ERROR" != 0 ]; then
	"Error making, ${LONGCMSSW}/src/CMS2/NtupleMacros/Tools/MiniFWLite/Makefile. Exiting"
	exit $ERROR
fi

cd -

cp ${LONGCMSSW}/src/CMS2/NtupleMacros/Tools/MiniFWLite/libMiniFWLite.so ${OUTLOCATION}/libMiniFWLite_${SHORTCMSSW}.so

ERROR=$?
if [ "$ERROR" != 0 ]; then
	"Error ${LONGCMSSW}/src/CMS2/NtupleMacros/Tools/MiniFWLite/libMiniFWLite.so to ${OUTLOCATION}/libMiniFWLite_${SHORTCMSSW}.so. Exiting"
	exit $ERROR
fi

exit 0