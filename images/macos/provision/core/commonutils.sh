#!/bin/bash -e -o pipefail
source ~/utils/utils.sh

# Monterey needs future review:
# aliyun-cli, gnupg, helm have issues with building from the source code.
# Added gmp for now, because toolcache ruby needs its libs. Remove it when php starts to build from source code.
common_packages=$(get_toolset_value '.brew.common_packages[]')
for package in $common_packages; do
    echo "Installing $package..."
    brew_smart_install "$package"
done

cask_packages=$(get_toolset_value '.brew.cask_packages[]')
for package in $cask_packages; do
    echo "Installing $package..."
    brew install --cask $package
done

# Install packages which should be removed after security preferences update 
brew install --cask macfuse

# Execute AppleScript to change security preferences
# System Preferences -> Security & Privacy -> General -> Unlock -> Allow -> Not now
if is_BigSur; then
    osascript $HOME/utils/confirm-identified-developers.scpt $USER_PASSWORD
fi

# Remove temporary packages
brew uninstall macfuse

# Specify Bazel version 3.7.1 to install due to the bug with 4.0.0: https://github.com/bazelbuild/bazel/pull/12882
if is_Less_Catalina; then
    export USE_BAZEL_VERSION="3.7.1"
    echo "export USE_BAZEL_VERSION=${USE_BAZEL_VERSION}" >> "${HOME}/.bashrc"
fi

# Invoke bazel to download bazel version via bazelisk
bazel

# Invoke tests for all basic tools
invoke_tests "BasicTools"
