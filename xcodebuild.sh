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

XCODE_ARGS="COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGNING_REQUIRED=NO"
XCODE_DESTINATION="platform=iOS Simulator,name=iPhone X"


# bundle exec xcpretty -v
set -o pipefail && xcodebuild clean build -sdk iphonesimulator -workspace Relisten.xcworkspace -scheme Relisten -destination="$XCODE_DESTINATION" $XCODE_ARGS | bundle exec xcpretty -f `xcpretty-travis-formatter`
