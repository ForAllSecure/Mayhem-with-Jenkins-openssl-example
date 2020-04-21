# 1) Build stage:
#
# All build tools required to build the project need to be installed
# here.
FROM debian:buster-slim as builder

# Install tools required for build
RUN apt update \
    && apt install -y cmake \
    build-essential \
    libc6-dbg

# Build the CLI
COPY . /home/workdir
WORKDIR /home/workdir
RUN ./config -DPEDANTIC no-shared
RUN make

# 2) Target stage:
#
# The binary is copied over from the build stage into this image. This is
# done to reduce the size of the image uploaded to Mayhem.
FROM debian:buster-slim

# Install libc debug package for valgrind support
RUN apt update \
    && apt install -y libc6-dbg

WORKDIR /home/workdir
COPY --from=builder /home/workdir/apps/openssl /home/workdir/mayhem/
