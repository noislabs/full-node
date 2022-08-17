#!/bin/sh

#The following is needed to make MACOS work with sed like linux
if [[ $OSTYPE == 'darwin'* ]]; then
  echo 'Runing on macOS'
  if ! command -v gsed &> /dev/null
  then
      brew install gsed  
  fi
  alias sed='gsed'
fi




. ../full-node/setup.sh
cd ..
#BINARY_NAME=wasmd/build/$BINARY_NAME
PATH=$PATH:$PWD/wasmd/build/
$BINARY_NAME version
EXEC_MODE="genesis"
HOME_DIR=$HOME/.$BINARY_NAME
ROOT_DIR=$PWD
CHAIN_ID=nois-localnet-000
. ../full-node/startup.sh