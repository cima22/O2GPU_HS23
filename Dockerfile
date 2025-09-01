FROM registry.cern.ch/alisw/slc9-gpu-builder

RUN mkdir -p /alice_hs23/standalone/events
WORKDIR /alice_hs23

ENV O2_RELEASE=daily-20250719-0000
ENV MODULEPATH=/cvmfs/alice.cern.ch/etc/toolchain/modulefiles/el9-x86_64:/cvmfs/alice.cern.ch/el9-x86_64/Modules/modulefiles

COPY entrypoint.sh entrypoint.sh

COPY run.sh run.sh

COPY cmake.patch cmake.patch

COPY o2-pbpb-50kHz-32 standalone/events/o2-pbpb-50kHz-32

RUN chmod +x entrypoint.sh run.sh

ENTRYPOINT ["/alice_hs23/entrypoint.sh"]