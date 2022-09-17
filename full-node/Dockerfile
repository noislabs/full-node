FROM golang:buster as go_builder
ARG BINARY_NAME=noisd

RUN apt update && apt install -y git build-essential
COPY setup.sh .
RUN ./setup.sh

# Finds dynamic libraries installed in the Go package management system, like
#   /go/pkg/mod/github.com/!cosm!wasm/wasmvm@v1.0.0/api/libwasmvm.aarch64.so
#   /go/pkg/mod/github.com/!cosm!wasm/wasmvm@v1.0.0/api/libwasmvm.x86_64.so
RUN find "$GOPATH/pkg" -type f -name 'libwasm*.so' -exec cp {} /go/out \;

FROM ubuntu:20.04
ENV LD_LIBRARY_PATH=/root
ENV PATH=$PATH:/root
RUN apt-get update && apt-get install -y \
    curl jq vim\
 && rm -rf /var/lib/apt/lists/*
COPY --from=go_builder /go/out/$BINARY_NAME /root/$BINARY_NAME
COPY --from=go_builder /go/out/libwasmvm*.so /root
COPY startup.sh .
ENTRYPOINT ["./startup.sh"]
