#!/bin/bash

set -e

source /etc/profile.d/modules.sh
module load boost/v1.90.0-alice1-2 CMake/v4.1.4-2 Clang/v20.1.7-20 ninja/fortran-v1.11.1.g9-25 ROOT/v6-36-10-alice1-1 \
            Vc/1.4.5-19 fmt/11.1.2-21 ms_gsl/4.2.1-12 TBB/v2022.3.0-11 ONNXRuntime/v1.22.0-1 GLFW/3.4-5
            
cd /alice_hs23/standalone

BACKEND_FLAG="-g"
while getopts "c" opt; do
    case $opt in
        c) BACKEND_FLAG="-c" ;;
        *) echo "Usage: $0 [-c]" >&2; exit 1 ;;
    esac
done

BENCH_CONF="-e o2-pbpb-50kHz-32 $BACKEND_FLAG --memSize 15000000000 --preloadEvents --runs 5"
RTC_CONF="--RTCenable 1 --RTCcacheOutput 1 --RTCoptConstexpr 1 --RTCcompilePerKernel 1"

./ca --sync $BENCH_CONF $RTC_CONF 2>&1 | tee syncProcessing.log

./ca --syncAsync $BENCH_CONF 2>&1 | tee asyncProcessing.log