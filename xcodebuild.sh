#!/bin/bash

command -v xcpretty >/dev/null 2>&1 || {
    gem install xcpretty 2>&1 || { 
        echo "Failed to install xcpretty. Aborting"
        exit 1
    }
    command -v xcpretty >/dev/null 2>&1 || { 
        echo "Still couldn't find xcpretty after installing it. Womp womp"
        exit 1
    }
}

xcodebuild clean build -sdk iphonesimulator -workspace Relisten.xcworkspace -scheme Relisten CODE_SIGNING_REQUIRED=NO | xcpretty && exit ${PIPESTATUS[0]}

