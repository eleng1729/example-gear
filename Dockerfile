FROM ubuntu:latest

RUN apt-get update \
 && apt-get install -q -y --no-install-recommends \
    python3 \
    python3-pip \
    xorg \
    unzip \
    wget \
    curl \
 && pip3 install flywheel-sdk \
 && pip3 install pandas \
 && pip3 install scikit-learn \
 && pip3 install SimpleITK \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ENV FLYWHEEL=/flywheel/v0
RUN mkdir -p ${FLYWHEEL}
COPY main.py ${FLYWHEEL}/main.py

# Download the MCR from MathWorks site and install with -mode silent
RUN mkdir /mcr-install && \
    mkdir /opt/mcr && \
    cd /mcr-install && \
    wget --no-check-certificate -q https://ssd.mathworks.com/supportfiles/downloads/R2021b/Release/3/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2021b_Update_3_glnxa64.zip && \
    unzip -q MATLAB_Runtime_R2021b_Update_3_glnxa64.zip && \
    rm -f MATLAB_Runtime_R2021b_Update_3_glnxa64.zip && \
    ./install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent && \
    cd / && \
    rm -rf mcr-install

# Configure environment variables for MCR
ENV LD_LIBRARY_PATH /opt/mcr/v911/runtime/glnxa64:/opt/mcr/v911/bin/glnxa64:/opt/mcr/v911/sys/os/glnxa64:/opt/mcr/v911/extern/bin/glnxa64
ENV XAPPLRESDIR /etc/X11/app-defaults

# ADD the Matlab Stand-Alone (MSA) into the container
COPY src/bin/*fitT2Map* /usr/local/bin/

# Ensure that the executable files are executable
RUN chmod +x /usr/local/bin/*fitT2Map*

# Copy and configure run script and metadata code
COPY manifest.json ${FLYWHEEL}/manifest.json

ENTRYPOINT ["bash wrapper.sh"]