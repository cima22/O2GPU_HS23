#!/bin/bash

#docker run -ti --rm -v /cvmfs:/cvmfs --device=/dev/kfd --device=/dev/dri alice_gpu_hs23 --backend [CUDA/HIP]  --arch ["arch1;arch2;..."]

set -e

while [[ $# -gt 0 ]]; do
  case $1 in
    --backend)
      BACKEND="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac

done

if [[ "$BACKEND" != "CUDA" && "$BACKEND" != "HIP" ]]; then
  echo "Error: unknown --backend: must be either CUDA or HIP (got '$BACKEND')"
  exit 1
fi

source /etc/profile.d/modules.sh
module load O2/"$O2_RELEASE"-1 boost/v1.83.0-alice2-45 CMake/v3.31.6-4 Clang/v18.1.8-22 ninja/fortran-v1.11.1.g9-12 ROOT/v6-32-06-alice9-3

git clone https://github.com/AliceO2Group/AliceO2.git O2
cd O2
git checkout "$O2_RELEASE"
cd ..

LD_LIBRARY_PATH+=$(find /usr/local/cuda* -type d -name stubs -prune -false -o \( -type f -o -type l \) -name libcuda.so -printf ':%h' -quit)

mkdir -p standalone/build
patch O2/GPU/GPUTracking/Standalone/cmake/config.cmake < cmake.patch

echo "set(ENABLE_${BACKEND} ON)" >> O2/GPU/GPUTracking/Standalone/cmake/config.cmake

if [[ "$BACKEND" == "HIP" ]]; then
  echo "set(HIP_AMDGPUTARGET \"${ARCH}\")" >> O2/GPU/GPUTracking/Standalone/cmake/config.cmake
elif [[ "$BACKEND" == "CUDA" ]]; then
  echo "set(CUDA_COMPUTETARGET \"${ARCH}\")" >> O2/GPU/GPUTracking/Standalone/cmake/config.cmake
fi

cd standalone/build
cmake -DCMAKE_INSTALL_PREFIX=../ ../../O2/GPU/GPUTracking/Standalone/
make -j$(nproc) install
cd ..

./ca --noEvents -g --gpuType $BACKEND --RTCenable 1 --RTCcacheOutput 1 --RTCoptConstexpr 1 --RTCcompilePerKernel 1 --RTCTECHrunTest 2

if [ $? -eq 0 ]; then
  echo "✅ Build completed, binaries ready to be executed!"
else
  echo "❌ Error: cannot Runtime Compile!"
fi

tail -f /dev/null
