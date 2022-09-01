#!/bin/sh

#set -ue

BINARY_NAME=noisd
BECH32_PREFIX=nois
WASMD_VERSION=0.28.0
WASMD_TAG="v$WASMD_VERSION"

# Re-create tmp directory
rm -rf tmp && mkdir tmp

(
  cd tmp
  git clone https://github.com/CosmWasm/wasmd.git
  (
    cd wasmd
    git checkout "${WASMD_TAG}"
    WASMD_COMMIT_HASH=$(git rev-parse HEAD)
    mkdir build
    go build \
        -o build/$BINARY_NAME -mod=readonly -tags "netgo,ledger" \
        -ldflags "-X github.com/cosmos/cosmos-sdk/version.Name=$BINARY_NAME \
        -X github.com/cosmos/cosmos-sdk/version.AppName=$BINARY_NAME \
        -X github.com/CosmWasm/wasmd/app.NodeDir=.$BINARY_NAME \
        -X github.com/cosmos/cosmos-sdk/version.Version=${WASMD_VERSION} \
        -X github.com/cosmos/cosmos-sdk/version.Commit=${WASMD_COMMIT_HASH} \
        -X github.com/CosmWasm/wasmd/app.Bech32Prefix=${BECH32_PREFIX} \
        -X 'github.com/cosmos/cosmos-sdk/version.BuildTags=netgo,ledger'" \
        -trimpath ./cmd/wasmd
  )
)

mkdir -p out
cp tmp/wasmd/build/noisd out
