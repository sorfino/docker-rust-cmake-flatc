ARG FLATBUFFERS_IMAGE_BASE="debian"
ARG FLATBUFFERS_IMAGE_TAG="bullseye-slim"

FROM ${FLATBUFFERS_IMAGE_BASE}:${FLATBUFFERS_IMAGE_TAG} as flatbuffer_build

ARG FLATBUFFERS_BUILD_TYPE="Release"
ARG FLATBUFFERS_ARCHIVE_BASE_URL="https://api.github.com/repos/google/flatbuffers/tarball"
ARG FLATBUFFERS_ARCHIVE_TAG="master"

ARG FLATBUFFERS_USE_CLANG="true"

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget clang ca-certificates make 

ARG CMAKE_VERSION="3.26"
ARG CMAKE_BUILD="1"

RUN wget https://cmake.org/files/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.${CMAKE_BUILD}.tar.gz \
    && tar xzf cmake-${CMAKE_VERSION}.${CMAKE_BUILD}.tar.gz \
    && cd cmake-${CMAKE_VERSION}.${CMAKE_BUILD} \
    && ./bootstrap -- -DCMAKE_USE_OPENSSL=OFF \
    && make \
    && make install

RUN wget -O flatbuffers.tar.gz "${FLATBUFFERS_ARCHIVE_BASE_URL}/${FLATBUFFERS_ARCHIVE_TAG}" \
    && tar xzf flatbuffers.tar.gz \
    && mv google-flatbuffers-* flatbuffers \
    && cd flatbuffers \
    && cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=${FLATBUFFERS_BUILD_TYPE} \
    && make \
    && make test \
    && make install


FROM rust:1-slim

COPY --from=flatbuffer_build /usr/local/bin/flatc /usr/local/bin/flatc
COPY --from=flatbuffer_build /usr/local/include/flatbuffers /usr/local/include/flatbuffers
COPY --from=flatbuffer_build /usr/local/lib/libflatbuffers.a /usr/local/lib/libflatbuffers.a
COPY --from=flatbuffer_build /usr/local/lib/cmake/flatbuffers /usr/local/lib/cmake/flatbuffers

RUN apt-get update && apt-get install -y cmake \
    && flatc --version


