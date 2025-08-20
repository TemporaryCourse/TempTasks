#!/bin/bash

# exit script on failure
set -ev

git clone https://github.com/google/swiftshader
cd swiftshader
git checkout 5b45bdb479fabe8468f0273d89bde242af002196
mkdir build-release
cd build-release
cmake ..
cmake --build . --parallel
./vk-unittests

VK_ICD_FILENAMES=`pwd`/Linux/vk_swiftshader_icd.json vulkaninfo --summary # should show:
# deviceType = PHYSICAL_DEVICE_TYPE_CPU
#	deviceName = SwiftShader Device (LLVM 10.0.0)
# driverName = SwiftShader driver
