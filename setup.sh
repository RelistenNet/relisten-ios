#!/bin/bash

function printProgress {
    printf "\033[0;33m%-70s" "$1" 
}

function printSuccess {
    if [ -z "$1" ]; then
        message="DONE"
    else 
        message=$1
    fi
    printf "\033[0;32m[\033[1;32m $message \033[0;32m]\033[0m\n" 
}

function printFailure {
    if [ -z "$1" ]; then
        message="ERROR"
    else 
        message=$1
    fi
    printf "\033[0;32m[\033[1;31m $message \033[0;32m]\033[0m\n"
}

runCmd ()
{
    if [ -z "$2" ]; then 
        return 1
    fi
    cmd=$1
    title=$2
    if [ -z "$3" ]; then
        expect=0
    else
        expect=$3
    fi
    if [ -z "$4" ]; then
        log=`mktemp -t scriptcommand`
        shouldRemove=1
    else
        log=$4
        shouldRemove=0
    fi

    retval=0

    printProgress "$title"
    printf "$cmd\n" > $log
    $cmd >> $log 2>&1
    result=$?

    if [[ "$result" == "$expect" ]]; then
        printSuccess
    else
        retval=1
        printFailure
        printf "Last 10 lines of output (full log is at $log):\n"
        tail -n 10 $log
        shouldRemove=0
    fi

    if [ $shouldRemove == "1" ]; then
        rm $log
    fi

    if [ "$retval" != "0" ]; then
        exit 1
    fi
}

function checkAndClone {
    projectName=$1
    projectURL=$2
    if  [ -z $3 ]; then
        projectBasePath=".."
    else
        projectBasePath=$3
    fi
    
    if [ ! -d "$projectBasePath/$1" ]; then
        runCmd "git clone --quiet $2 $projectBasePath/$1" "Cloning $1"
    else
        printProgress "Checking $1"
        printSuccess
    fi
}

function usage {
    printf "Use: $0 [-n] [-l path]\n"
    printf "\t-n\tDon't install CocoaPods\n"
    printf "\t-l\tClone development pods into a subdirectory\n"
}

shouldInstallPods=1
podBasePath=".."
while getopts "nhl:" o; do
    case "${o}" in
        n)
            shouldInstallPods=0
            ;;
        l)
            podBasePath=${OPTARG}
            mkdir -p $podBasePath
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Belt and suspenders
is_ci=0
pod_command="pod"
if [[ ! -z ${CI} ]]; then 
    echo "Running under continuous integration"
    podBasePath="CIPods"
    pod_command="bundle exec pod"
    is_ci=1
fi

checkAndClone BASSGaplessAudioPlayer https://github.com/alecgorge/gapless-audio-bass-ios.git $podBasePath
checkAndClone AGAudioPlayer https://github.com/alecgorge/AGAudioPlayer.git $podBasePath

if [[ $shouldInstallPods == 1 ]]; then

    printProgress "Checking for CocoaPods"
    command -v $pod_command >/dev/null 2>&1 || { 
        printFailure
        echo >&2 "Cocoapods is not installed. Please install it from https://cocoapods.org and try again."
        exit 1
    }
    printSuccess
    if [[ $is_ci == 1 ]]; then
        runCmd "$pod_command install --repo-update" "Installing pods"
    else 
        runCmd "$pod_command install" "Installing pods"
    fi
fi

printf "\n\n✅ Success! Open \033[0;33mRelisten.xcworkspace\033[0m to build the app.\n"
exit 0
