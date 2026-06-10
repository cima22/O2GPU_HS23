FROM registry.cern.ch/alisw/slc9-gpu-builder

RUN mkdir -p /alice_hs23/standalone/events
WORKDIR /alice_hs23

ENV O2_RELEASE=daily-20260602-0000
RUN git clone https://github.com/AliceO2Group/AliceO2.git O2 && \
    cd O2 && git checkout "$O2_RELEASE"

ENV MODULEPATH=/cvmfs/alice.cern.ch/etc/toolchain/modulefiles/el9-x86_64:/cvmfs/alice.cern.ch/el9-x86_64/Modules/modulefiles

COPY entrypoint.sh entrypoint.sh

COPY run.sh run.sh

COPY cmake.patch cmake.patch

# Event data is too large for git, so it is downloaded at build time from a CERNBox public link. Override with --build-arg DATA_URL=<url> if it moves.
ARG DATA_URL=https://cernbox.cern.ch/s/CG0hOekKzLcd43s/download
RUN curl -fSL "$DATA_URL" -o /tmp/data.tar && \
    tar -xf /tmp/data.tar -C standalone/events && \
    rm /tmp/data.tar

RUN chmod +x entrypoint.sh run.sh

ENTRYPOINT ["/alice_hs23/entrypoint.sh"]