# This file is part of xrootdpyfs
# Copyright (C) 2015-2020 CERN.
#
# xrootdpyfs is free software; you can redistribute it and/or modify it under
# the terms of the Revised BSD License; see LICENSE file for more details.
#
# Dockerfile for running XRootDPyFS tests.
#
# Usage:
#   docker build -t xrootd . && docker run -h xrootdpyfs -it xrootd

FROM centos:7

# Install xrootd
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum group install -y "Development Tools"
RUN yum-config-manager --add-repo https://xrootd.slac.stanford.edu/binaries/xrootd-stable-slc7.repo
RUN yum --setopt=obsoletes=0 install -y cmake \
                                        gcc-c++ \
                                        zlib-devel \
                                        openssl-devel \
                                        libuuid-devel \
                                        git \
                                        wget \
                                        python3 \
                                        python3-pip \
                                        python3-devel \
                                        xrootd-client \
                                        xrootd
RUN adduser --uid 1001 xrootdpyfs
# Install some prerequisites ahead of `setup.py` in order to profit
# from the docker build cache:
RUN pip3 install --upgrade pip setuptools
RUN pip3 install ipython \
                pydocstyle \
                coverage \
                pytest \
                pytest-pep8 \
                pytest-cov \
                isort \
                mock \
                wheel \
                Sphinx

# Ensure we install the same version as the RPM package.
RUN XROOTD_VERSION=`rpm --queryformat "%{VERSION}" -q xrootd-client` && \
    pip3 install xrootd==${XROOTD_VERSION}

RUN pip3 install "fs<2.0"

# Add sources to `code` and work there:
WORKDIR /code
COPY . /code

RUN pip3 install -e .

RUN chown -R xrootdpyfs:xrootdpyfs /code && chmod a+x /code/run-docker.sh && chmod a+x /code/run-tests.sh

USER xrootdpyfs

RUN mkdir /tmp/xrootdpyfs && echo "Hello XRootD!" >> /tmp/xrootdpyfs/test.txt

# Print xrootd version
RUN xrootd -v

CMD ["bash", "/code/run-docker.sh"]
