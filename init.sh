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
# Check if DEPENDENCY_MANAGER environment variable is set
if [ -n "$DEPENDENCY_MANAGER" ]; then
    manager="$DEPENDENCY_MANAGER"
    echo "Using DEPENDENCY_MANAGER from environment: $manager"
else
    read -p "Choose your dependency manager (spm/cocoapods) [cocoapods]: " manager
    manager=${manager:-cocoapods}
fi

if [ "$manager" = "spm" ]; then
    echo "Initializing with spm..."
    cd $SPM_PROJECT_PATH
    tuist install
    tuist generate
elif [ "$manager" = "cocoapods" ]; then
    echo "Initializing with cocoapods..."
    cd $COCOAPODS_PROJECT_PATH
    
    # Read COCOAPODS_MODE environment variable and use it as parameter
    if [ -n "$COCOAPODS_MODE" ]; then
        echo "Using COCOAPODS_MODE: $COCOAPODS_MODE"
        ./generate.sh $COCOAPODS_MODE $SCRIBBLE_VERSION
    else
        echo "COCOAPODS_MODE not set, using default: sourcecode"
        ./generate.sh
    fi
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo "Initialization with $manager completed."
