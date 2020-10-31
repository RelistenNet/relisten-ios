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
DESTINATION=`xcrun simctl list devices available iPhone | sed -nE 's/^ +(iPhone[^\(]*) \(.*/\1/gp' | grep -v "SE" | sort -V | tail -n1`

XCODE_ARGS="COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGNING_REQUIRED=NO"
XCODE_DESTINATION="platform=$PLATFORM,name=$DESTINATION"

BUILD_COMMAND="build-for-testing"
if [[ $1 == "test" ]]; then
    BUILD_COMMAND="test-without-building"
fi

# bundle exec xcpretty -v
set -o pipefail && xcodebuild $BUILD_COMMAND -sdk iphonesimulator -workspace Relisten.xcworkspace -scheme Relisten -destination "$XCODE_DESTINATION" $XCODE_ARGS | bundle exec xcpretty -f `xcpretty-travis-formatter`
