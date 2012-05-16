#! /bin/bash

## FUNCTIONS
die(){
#@ DESCRIPTION: print error message and exit with supplied return code
#@ USAGE: die STATUS [MESSAGE]
        error=$1
        shift
        [ -n "$*" ] && printf "\n%s\n" "$*" >&2
        exit "$error"
}

usage(){
#@ DESCRIPTION: print usage information
#@ USAGE: usage 
        printf "\n*-------------------------------------- USAGE for %s ----------------------------------------*\n" "$scriptname" 
        printf "%s\n" "$usage" 
        printf "\n\n\n" 
}

## INITIALIZE VARIABLES
scriptname=${0##*/}
usage="   arg1 = CMSSW Release
   arg2 = CMS2 Tag
   arg3 = Checkout Location
   arg4 = Scram Arch"


: ${1?"No specified CMSSW Release (arg 1). Exiting"}
: ${2?"No specified CMS2 Tag (arg 2). Exiting"}
: ${3?"No specified Checkout Location (arg 3). Exiting"}
: ${4?"No specified Scram Arch (arg 4). Exiting"}

release=$1
printf "%20s  %s\n" "CMSSW Release:" "$release"
tag=$2
printf "%20s  %s\n" "CMS2 Tag:" "$tag"
location=$3
printf "%20s  %s\n" "Checkout Location:" "$location"
full_name="${release}_${tag}"
if [ ! -d "$location" ]; then
    echo "Specified checkout location, $location, does not exist. Creating dir now."
    mkdir -p $location
fi

if [ ! -d "$location" ]; then
    die 1 "Failed to make dir, $location. Exiting"
fi

cd "$location" 
source /code/osgcode/cmssoft/cmsset_default.sh  > /dev/null 2>&1
export SCRAM_ARCH="$4"
export CVSROOT=:pserver:anonymous:98passwd@cmssw.cvs.cern.ch:/local/reps/CMSSW/
export CVS_RSH=ssh

if [ -d "$full_name" ]; then
	echo "CMSSW Release already checked out."
else
	echo "Checking out CMSSW Release."
    scramv1 p -n $full_name CMSSW $release
	release_error=$?
	if [ $release_error != 0 ]; then
		echo "Failed to checkout CMSSW release. Exiting."
		exit $release_error
	fi
fi

echo "Cding into Dir:     ${release}/src"
cd ${full_name}/src
echo "Setting up CMSSW Environment"
eval `scram runtime -sh`

if [ -d "CMS2" ]; then
	echo "Found CMS2 already checked out. Will proceed to building."
else
	echo "Did not find CMS2. Will check out."
	cvs co -r $tag -d CMS2 UserCode/JRibnik/CMS2
	checkout_error=$?
	if [ $checkout_error != 0 ]; then
		echo "Failed to checkout CMS2. Exiting."
		exit $checkout_error
	fi
#     cvs co -r $tag -d CMS2/Dictionaries UserCode/JRibnik/CMS2/Dictionaries
#     cvs co -r $tag -d CMS2/Configuration UserCode/JRibnik/CMS2/Configuration
#     cvs co -r $tag -d CMS2/NtupleMaker UserCode/JRibnik/CMS2/NtupleMaker

	patchesV=${release#*_}
	if [[ $patchesV = *[a-zA-Z]* ]]; then
		patchesV=${patchesV%_*}
	fi
	patchesV=`echo $patchesV | sed 's/_//g'`
	printf "%20s  %s" "Patches Version:" "$patchesV"
	
    source CMS2/Configuration/patchesToSource.sh.${patchesV}
fi
echo "Running scram on CMS2"
scramv1 b -j 25

error=$?
	
if [ $error = 0 ]; then
	echo "Compilation successful."
else
	echo "Compilation failed."
fi	
exit "$error"