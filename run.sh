#!/bin/bash

set -e

source /etc/profile.d/modules.sh
module load O2/"$O2_RELEASE"-1 boost/v1.83.0-alice2-45 CMake/v3.31.6-4 Clang/v18.1.8-22 ninja/fortran-v1.11.1.g9-12 ROOT/v6-32-06-alice9-3

cd /alice_hs23/standalone

BENCH_CONF="-e o2-pbpb-50kHz-32 -g --memSize 15000000000 --preloadEvents --runs 5"
RTC_CONF="--RTCenable 1 --RTCcacheOutput 1 --RTCoptConstexpr 1 --RTCcompilePerKernel 1"

./ca --sync $BENCH_CONF $RTC_CONF 2>&1 | tee syncProcessing.log

./ca --syncAsync $BENCH_CONF 2>&1 | tee asyncProcessing.log