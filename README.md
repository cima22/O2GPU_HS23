# ALICE GPU workload for HEPScore23
This repository provides the necessary files to compile and run the ALICE GPU workload for HS23.
## Quickstart
### Build
To build, it is necessary to specify a backend (either `CUDA` or `HIP`) and one or more GPU architectures for which to build the benchmark:
```
docker run -d --name standalone_benchmark -v /cvmfs:/cvmfs alice_gpu_hs23 --backend [CUDA/HIP] --arch ["arch1;arch2;..."]
```
Example for building for Nvidia A100 GPU (sm_80):
```
docker run -d --name standalone_benchmark -v /cvmfs:/cvmfs alice_gpu_hs23 --backend CUDA --arch 80
```
Optionally, a backend for `OpenCL` is also available.
### Run
To run inside the container:
```
docker exec -it standalone_benchmark ./run.sh
```
**Note**: If both `Docker` and `CVMFS` are available, the benchmark can be built on any machine. However, to execute the benchmark inside the container, the target GPU must be accessible to that container, and compatible GPU drivers must be present. For example, for AMD GPUs, add `--device=/dev/kfd --device=/dev/dri` when running the container.
## The workload
This repository builds the Time Projection Chamber (TPC) [1] standalone benchmark. The TPC is ALICE’s drift detector, responsible for roughly 90% of the data collected [2]. Being a triggerless experiment, ALICE records all raw data coming from the detectors. Thus, to store all information from the TPC, the full tracking of all TPC events is performed during data taking, ensuring a better compression ratio of the detected clusters [3]. To sustain the data throughput, 2800 GPUs are employed during data taking for TPC track reconstruction[4]. The purpose of the `standalone benchmark` is to make the TPC reconstruction code available standalone.\
The `standalone benchmark` can be summarised as follows:
- **Input**: ALICE's computing unit is the TimeFrame (TF), representing a specific time window of data (default is ~2.8 ms, or 32 LHC orbits). The algorithm processes one or more TF dumps, each containing raw TPC hits detected during that time window.
- **Algorithm**: The benchmark performs track reconstruction on the input data, which can be executed entirely on a single GPU. Two execution modes are available: `--sync` and `--syncAsync`.
  - **`--sync`**: Runs the benchmark under the same conditions used for TPC track reconstruction during data taking. This includes a clusterizer step to find clusters of hits left by the same particle, track fitting and merging. After tracking, a compression step is applied to the found TPC clusters using the information extracted from the reconstruction.
  - **`--syncAsync`**: First performs the full `--sync` part, then runs an additional tracking step on the compressed clusters produced in the `--sync` phase. Hence, the decompression is performed at the beginning of the asynchronous part, and the clusterizer step is skipped. This emulates the actual *asynchrnous reconstruction* that runs on clusters from Compressed TFs (CTFs).
- **Output**: The benchmark outputs information about the processing steps, with the amount of detail depending on the selected debug level. Example of output when running with `--syncAsync` with the lowest debug level:
```
Running synchronous phase
Event has 238198 8kb TPC ZS pages (version 4), 523415891 digits
Event has 71586810 TPC Clusters, 0 TRD Tracklets
Output Tracks: 656913 (0 / 48346781 / 0 / 71586810 clusters (fitted / attached / adjacent / total) - O2 format)
Total Wall Time:    6341192 us
Running asynchronous phase
Event has 64920081 TPC Clusters, 0 TRD Tracklets
Output Tracks: 506855 (0 / 42708609 / 0 / 64920081 clusters (fitted / attached / adjacent / total) - O2 format)
Total Wall Time:    3991905 us
```

## `entrypoint.sh`
The `entrypoint.sh` script builds the benchmark software. It performs the following steps:
1. Loads the required modules for building the benchmark from `CVMFS`.
2. Clones `O2` repository and checks out a specific release.
3. Patches `config.cmake` with the desired GPU backend and architecture.
4. Builds the `standalone benchmark` in the `standalone` folder.
5. Runs an initial test to generate the *RunTimeCompilation (RTC) cache*.

## `run.sh`
The `run.sh` script executes the benchmark. It performs the following steps:
1. Loads the dependencies from `CVMFS`
2. Executes the benchmark in `--sync` mode:
   - Takes in input the TF dump present in the folder `o2-pbpb-50kHz-32`. It contains the dump from a simulated TF with Pb-Pb interactions at 50 kHz. 
   - During data taking, the GPU source code is *run-time compiled* to enable further compiler optimisations. The standalone benchmark has already generated the *RTC cache* during build, so the executable simply loads the cache, reads the dump, and performs tracking **5 times**.
3. Executes the benchmark in `--syncAsync` mode:
   - RTC is skipped, as asynchronous reconstruction does not use it.
   - Loads the dump file and executes the *synchronous* and *asynchronous* parts **5 times**.

**Note:** The benchmark uses 1 GPU and 1 CPU core to steer the execution.

## HS23 metric
TBD

## Run outside the container
1. Copy the `standalone` folder:
```
docker cp standalone_benchmark:/alice_hs23/standalone /path/to/local/standalone
```
2. Set the following env variables:
```
export O2_RELEASE=daily-20250719-0000
export MODULEPATH=/cvmfs/alice.cern.ch/etc/toolchain/modulefiles/el9-x86_64:/cvmfs/alice.cern.ch/el9-x86_64/Modules/modulefiles:$MODULEPATH
export LD_LIBRARY_PATH=/path/to/local/standalone:$LD_LIBRARY_PATH
```
3. Load the modules from `CVMFS`:
```
module load O2/"$O2_RELEASE"-1 boost/v1.83.0-alice2-45 CMake/v3.31.6-4 Clang/v18.1.8-22 ninja/fortran-v1.11.1.g9-12 ROOT/v6-32-06-alice9-3
```
4. Launch the benchmark via the `./ca` executable.


## Further documentation
- [Standalone-benchmark](https://github.com/AliceO2Group/AliceO2/blob/dev/GPU/documentation/build-standalone.md)
- [Run-Time-Compilation](https://github.com/AliceO2Group/AliceO2/blob/dev/GPU/documentation/run-time-compilation.md)
- [Build O2 for GPUs](https://github.com/AliceO2Group/AliceO2/blob/dev/GPU/documentation/build-O2.md)
- [O2](https://aliceo2group.github.io)
- [O2 github repository](https://github.com/AliceO2Group/AliceO2)

## References
[1]: J. Adolfsson et al., “The upgrade of the ALICE TPC with GEMs and continuous readout,” *Journal of Instrumentation*, vol. 16, no. 03, P03022, Mar. 2021. ISSN: 1748-0221. [DOI: 10.1088/1748-0221/16/03/p03022](http://dx.doi.org/10.1088/1748-0221/16/03/p03022)\
[2]: David Rohr, “Usage of GPUs in ALICE Online and Offline processing during LHC Run 3,” *EPJ Web Conf.*, vol. 251, p. 04026, 2021. [DOI: 10.1051/epjconf/202125104026](https://doi.org/10.1051/epjconf/202125104026)\
[3]: David Rohr, "Global Track Reconstruction and Data Compression Strategy in ALICE for LHC Run 3", 2019. [arXiv:1910.12214](https://arxiv.org/abs/1910.12214)\
[4]: Federico Ronchetti et al., "Efficient high performance computing with the ALICE Event Processing Nodes GPU-based farm", 2024. [arXiv:2412.13755](https://arxiv.org/abs/2412.13755)
