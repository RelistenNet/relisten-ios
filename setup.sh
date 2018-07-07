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
    
    if [ ! -d "../$1" ]; then
        runCmd "git clone --quiet $2 ../$1" "Cloning $1"
    else
        printProgress "Checking $1"
        printSuccess
    fi
}

checkAndClone NapySlider https://github.com/farktronix/NapySlider.git
checkAndClone BASSGaplessAudioPlayer https://github.com/alecgorge/gapless-audio-bass-ios.git
checkAndClone AGAudioPlayer https://github.com/alecgorge/AGAudioPlayer.git
checkAndClone fave-button https://github.com/alecgorge/fave-button.git

printProgress "Checking for CocoaPods"
command -v pod >/dev/null 2>&1 || { 
    printFailure
    echo >&2 "Cocoapods is not installed. Please install it from https://cocoapods.org and try again."
    exit 1
}
printSuccess
runCmd "pod install" "Installing pods"

printf "\n\n✅ Success! Open \033[0;33mRelisten.xcworkspace\033[0m to build the app.\n"
