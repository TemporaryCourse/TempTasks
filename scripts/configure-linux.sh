#!/bin/bash

# exit script on failure
set -ev

njobs=`grep -c '^processor' /proc/cpuinfo`

install_prefix=/usr/local

sudo apt update
sudo apt install -yq graphicsmagick-libmagick-dev-compat # we need Magick++.h so that CImg.h can load jpg files
sudo apt install -yq build-essential pkg-config libx11-dev libxrandr-dev # to fix #include <X11/extensions/Xrandr.h> when compiling Vulkan-Loader

googletest_version=1.10.0
vulkan_sdk_version=1.3.283
vulkan_headers_version=${vulkan_sdk_version}
vulkan_loader_version=${vulkan_sdk_version}
vulkan_spirv_reflect_version=${vulkan_sdk_version}
vulkan_validation_layers_version=${vulkan_sdk_version}

echo "Downloading sources"
wget https://github.com/google/googletest/archive/refs/tags/release-${googletest_version}.zip
wget https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v${vulkan_headers_version}.zip -O Vulkan-Headers-${vulkan_headers_version}.zip
wget https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/v${vulkan_loader_version}.zip -O Vulkan-Loader-${vulkan_loader_version}.zip
wget https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/19b940e864bd3a5afb3c79e3c6788869d01a19eb/include/vk_mem_alloc.h -O vk_mem_alloc.h
wget https://github.com/KhronosGroup/Vulkan-ValidationLayers/archive/refs/tags/v${vulkan_validation_layers_version}.zip -O Vulkan-ValidationLayers-${vulkan_validation_layers_version}.zip
wget https://github.com/KhronosGroup/SPIRV-Reflect/archive/refs/tags/vulkan-sdk-${vulkan_spirv_reflect_version}.0.zip -O SPIRV-Reflect-${vulkan_spirv_reflect_version}.zip
wget https://github.com/google/shaderc/archive/v2020.2.zip

echo "Installing googletest"
unzip release-${googletest_version}.zip
rm release-${googletest_version}.zip
pushd googletest-release-${googletest_version}
mkdir releasebuild
cd releasebuild
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${install_prefix} ..
make -j${njobs} install
popd
rm -rf googletest-release-${googletest_version}

echo "Installing Vulkan Headers"
unzip Vulkan-Headers-${vulkan_headers_version}.zip
rm Vulkan-Headers-${vulkan_headers_version}.zip
cd Vulkan-Headers-${vulkan_headers_version}
mkdir releasebuild
cd releasebuild
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${install_prefix} ..
make -j$njobs install
cd ../..
rm -rf Vulkan-Headers-${vulkan_headers_version}

echo "Installing Vulkan Loader"
unzip Vulkan-Loader-${vulkan_loader_version}.zip
rm Vulkan-Loader-${vulkan_loader_version}.zip
cd Vulkan-Loader-${vulkan_loader_version}
mkdir releasebuild
cd releasebuild
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${install_prefix} -DVULKAN_HEADERS_INSTALL_DIR=${install_prefix} ..
make -j$njobs install
cd ../..
rm -rf Vulkan-Loader-${vulkan_loader_version}

mkdir ${install_prefix}/include/vma
mv vk_mem_alloc.h ${install_prefix}/include/vma/vk_mem_alloc.h

echo "Installing glslc shaders compiler"
unzip v2020.2.zip
cd shaderc-2020.2/third_party
wget https://github.com/KhronosGroup/SPIRV-Headers/archive/1.5.3.reservations1.zip
unzip 1.5.3.reservations1.zip
mv SPIRV-Headers-1.5.3.reservations1 spirv-headers
wget https://github.com/KhronosGroup/SPIRV-Tools/archive/v2020.4.zip
unzip v2020.4.zip
mv SPIRV-Tools-2020.4/ spirv-tools
wget https://github.com/KhronosGroup/glslang/archive/SDK-candidate-26-Jul-2020.zip
unzip SDK-candidate-26-Jul-2020.zip
mv glslang-SDK-candidate-26-Jul-2020 glslang
cd ..
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DSHADERC_SKIP_TESTS=TRUE
make -j${njobs}
cp glslc/glslc /usr/bin/
cd ../..
rm v2020.2.zip
rm -rf shaderc-2020.2

echo "Installing Vulkan Validation Layers"
unzip Vulkan-ValidationLayers-${vulkan_validation_layers_version}.zip
cd Vulkan-ValidationLayers-${vulkan_validation_layers_version}
mkdir releasebuild -p
cd releasebuild
#   If you encounter something like:
# Cloning into '.'...
# error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: CANCEL (err 8)
# error: 1321 bytes of body are still expected
# fetch-pack: unexpected disconnect while reading sideband packet
# fatal: early EOF
# fatal: fetch-pack: invalid index-pack output
#   Run this:
# git config --global http.postBuffer 524288000
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${install_prefix} -DUPDATE_DEPS=ON -DBUILD_WERROR=ON -DBUILD_TESTS=OFF ..
make -j$njobs install
cp ${install_prefix}/lib/libVkLayer_khronos_validation.so /usr/lib/
cd ../..
rm Vulkan-ValidationLayers-${vulkan_validation_layers_version}.zip
rm -rf Vulkan-ValidationLayers-${vulkan_validation_layers_version}

echo "Installing Vulkan SPIRV Reflect"
unzip SPIRV-Reflect-${vulkan_spirv_reflect_version}.zip
rm SPIRV-Reflect-${vulkan_spirv_reflect_version}.zip
cd SPIRV-Reflect-vulkan-sdk-${vulkan_spirv_reflect_version}.0
mkdir releasebuild
cd releasebuild
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${install_prefix} ..
make -j$njobs install
cd ../..
rm -rf SPIRV-Reflect-vulkan-sdk-${vulkan_spirv_reflect_version}.0
