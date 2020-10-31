#!/bin/bash

command -v xcpretty >/dev/null 2>&1 || {
    gem install xcpretty xcpretty-travis-formatter 2>&1 || { 
        echo "Failed to install xcpretty. Aborting"
        exit 1
    }
    command -v xcpretty >/dev/null 2>&1 || { 
        echo "Still couldn't find xcpretty after installing it. Womp womp"
        exit 1
    }
}

PLATFORM="iOS Simulator"
DESTINATION=`xcrun simctl list devices available iPhone | sed -nE 's/^ +(iPhone[^\(]*) \(.*/\1/gp' | tail -n1`

XCODE_ARGS="COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGNING_REQUIRED=NO"
XCODE_DESTINATION="platform=$PLATFORM,name=$DESTINATION"


# bundle exec xcpretty -v
set -o pipefail && xcodebuild clean build -sdk iphonesimulator -workspace Relisten.xcworkspace -scheme Relisten -destination="$XCODE_DESTINATION" $XCODE_ARGS | bundle exec xcpretty -f `xcpretty-travis-formatter`
