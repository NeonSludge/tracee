FROM golang:1.15-buster as builder

RUN echo "deb http://apt.llvm.org/buster/ llvm-toolchain-buster-9 main" >> /etc/apt/sources.list && apt-key adv --keyserver hkps://keyserver.ubuntu.com --recv-keys 15CF4D18AF4F7421 && \
    DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y --no-install-recommends libelf-dev llvm-9-dev clang-9 && \ 
    (for tool in "clang" "llc" "llvm-strip"; do path=$(which $tool-9) && ln -s $path ${path%-*}; done)

WORKDIR /tracee

COPY . /tracee


FROM builder as build

RUN git submodule update --init && make build


# must run privileged and with linux headers mounted
# docker run --name tracee --rm --privileged --pid=host -v /lib/modules/:/lib/modules/:ro -v /usr/src:/usr/src:ro aquasec/tracee
FROM ubuntu:focal

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y --no-install-recommends libelf1 llvm clang

WORKDIR /tracee

COPY --from=build /tracee/dist/tracee /tracee/entrypoint.sh ./

ENTRYPOINT ["./entrypoint.sh", "./tracee"]
