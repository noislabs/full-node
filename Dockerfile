FROM golang:buster as go_builder
ARG BECH32_PREFIX=nois
ARG WASMD_VERSION=v0.28.0
ARG BINARY_NAME=noisd



RUN apt update && apt install -y git build-essential
COPY setup.sh .
RUN ./setup.sh

FROM ubuntu:20.04
ENV LD_LIBRARY_PATH=/root
ENV PATH=$PATH:/root
RUN apt-get update && apt-get install -y \
    curl \
 && rm -rf /var/lib/apt/lists/*
COPY --from=go_builder /go/wasmd/build/$BINARY_NAME /root/$BINARY_NAME
COPY --from=go_builder /go/wasmd/build/libwasmvm*.so /root
COPY entrypoint.sh .
ENTRYPOINT ["./entrypoint.sh"]
