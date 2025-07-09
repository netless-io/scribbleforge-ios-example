#!/bin/bash

SPM_PROJECT_PATH="Projects/SPM"
COCOAPODS_PROJECT_PATH="Projects/CocoaPods"

# check mise and tuist are installed.
if ! command -v mise &> /dev/null
then
    echo "mise is not installed. Please install it first."
    exit 1
fi

if ! command -v tuist &> /dev/null
then
    echo "tuist is not installed. Please install it first."
    exit 1
fi

# let user select to init project spm or cocoapods. default to cocoapods.
read -p "Choose your dependency manager (spm/cocoapods) [cocoapods]: " manager
manager=${manager:-cocoapods}

if [ "$manager" = "spm" ]; then
    echo "Initializing with spm..."
    cd $SPM_PROJECT_PATH
    tuist install
    tuist generate
elif [ "$manager" = "cocoapods" ]; then
    echo "Initializing with cocoapods..."
    cd $COCOAPODS_PROJECT_PATH
    tuist generate --no-open
    pod install
    open ./S11E-Pod.xcworkspace
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo "Initialization with $manager completed."
