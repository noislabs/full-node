#!/bin/sh

set -ex



ROOT_DIR="${ROOT_DIR:=/root}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROOT_DIR
PASSPHRASE="${PASSPHRASE:=passphrase}"
BINARY_NAME="${BINARY_NAME:=noisd}"
CHAIN_ID="${CHAIN_ID:=nois-testnet-001}"
MONIKER="${MONIKER:=nois-validator}"
HOME_DIR="${HOME_DIR:=$ROOT_DIR/.$BINARY_NAME}"
CONFIG_DIR="${CONFIG_DIR:=$HOME_DIR/config}"
DENOM="${DENOM:=nois}"
STAKE_DENOM="${STAKE_DENOM:=nois}"
EXEC_MODE="${EXEC_MODE:=validator}"
GENESIS_URL="${GENESIS_URL:=https://raw.githubusercontent.com/noislabs/testnets/testnet-001/nois-testnet-001/genesis.json}"
                            
MNEMONIC="${MNEMONIC:=cmV2ZWFsIGNvbWUgcmlkZSBmb3J0dW5lIGFkbWl0IGJyb2tlbiBjbGljayB0b3dlciBhZGRyZXNzIGNlbnN1cyByYWRpbyBsZWN0dXJlIGxpY2Vuc2UgZ29vc2UgZmV2ZXIgZGVmeSBwYXRpZW50IHNpYmxpbmcgcXVhbGl0eSBzaWNrIGNhYmluIGluZG9vciBwcmludCB0eXBpY2FsCg==}"
REMOTE_RPC_NODE="${REMOTE_RPC_NODE:=http://rpc-1.noislabs.com:80}"
PERSISTENT_PEERS="${PERSISTENT_PEERS:=7ddf3c60f9ed086eee142ffae23c490d9fc738ca@rpc-1.noislabs.com:32637}"
COMMISSION_RATE="${COMMISSION_RATE:=0.01}"




PATH=$ROOT_DIR:$PATH
cd $ROOT_DIR

if [ "$EXEC_MODE" = "genesis" ]; then
  if [ ! -f "$CONFIG_DIR/genesis.json" ]; then
    echo "initialising moniker"

    $BINARY_NAME init $MONIKER --chain-id $CHAIN_ID 2> /dev/null
    # staking/governance token is hardcoded in config, change this
    sed -i "s/\"stake\"/\"u${STAKE_DENOM}\"/" $CONFIG_DIR/genesis.json
    sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.025u'"${DENOM}"'"/' $CONFIG_DIR/app.toml
    sed -i '0,/enable = false/s//enable = true/g' $CONFIG_DIR/app.toml
    sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \["*"\]/' $CONFIG_DIR/config.toml
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/' $CONFIG_DIR/config.toml
    sed -i 's/swagger = false/swagger = true/' $CONFIG_DIR/app.toml
    sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_DIR/config.toml
    sed -i 's/^cors_allowed_origins =.*$/cors_allowed_origins = ["*"]/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_propose =.*$/timeout_propose = "300ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_propose_delta =.*$/timeout_propose_delta = "100ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_prevote =.*$/timeout_prevote = "300ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_prevote_delta =.*$/timeout_prevote_delta = "100ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_precommit =.*$/timeout_precommit = "300ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_precommit_delta =.*$/timeout_precommit_delta = "100ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_commit =.*$/timeout_commit = "1s"/' $CONFIG_DIR/config.toml
    sed -i 's/^snapshot-interval =.*$/snapshot-interval = 1000/' $CONFIG_DIR/app.toml

#    create accounts
    yes "${PASSPHRASE}" | $BINARY_NAME keys add node_admin 2>&1 >/dev/null | tail -n 1 > $HOME_DIR/mnemonic
    yes "${PASSPHRASE}" | $BINARY_NAME keys add secondary 2>&1 >/dev/null | tail -n 1 > $HOME_DIR/secondary_mnemonic
    mkdir $HOME_DIR/genesis_volume
    cp $HOME_DIR/mnemonic $HOME_DIR/genesis_volume/genesis_mnemonic
    cp $HOME_DIR/secondary_mnemonic $HOME_DIR/genesis_volume/secondary_mnemonic

#    add genesis accounts with some initial tokens
    GENESIS_ADDRESS=$(yes "${PASSPHRASE}" | $BINARY_NAME keys show node_admin -a)
    SECONDARY_ADDRESS=$(yes "${PASSPHRASE}" | $BINARY_NAME keys show secondary -a)
    yes "${PASSPHRASE}" | $BINARY_NAME add-genesis-account node_admin 1000000000000000u"${STAKE_DENOM}"
    yes "${PASSPHRASE}" | $BINARY_NAME add-genesis-account secondary  1000000000000000u"${STAKE_DENOM}"

    yes "${PASSPHRASE}" | $BINARY_NAME gentx node_admin 1000000000u"${STAKE_DENOM}" --chain-id $CHAIN_ID 2> /dev/null
    $BINARY_NAME collect-gentxs 2> /dev/null
    $BINARY_NAME validate-genesis > /dev/null
    cp $HOME_DIR/config/genesis.json $HOME_DIR/genesis_volume/genesis.json
  else
    echo "Validator already initialized, starting with the existing configuration."
    echo "If you want to re-init the validator, destroy the existing container"
	fi
	$BINARY_NAME start
elif [ "$EXEC_MODE" = "validator" ]; then
  if [ ! -f "$CONFIG_DIR/genesis.json" ]; then
    $BINARY_NAME init $MONIKER --chain-id $CHAIN_ID 2> /dev/null


    #cp $HOME_DIR/genesis_volume/genesis.json $CONFIG_DIR/genesis.json
    /usr/bin/curl $GENESIS_URL > $CONFIG_DIR/genesis.json

    sed -i 's/persistent_peers = ""/persistent_peers = "'"${PERSISTENT_PEERS}"'"/' $CONFIG_DIR/config.toml
    sed -i 's/seeds = ""/seeds = "'"${PERSISTENT_PEERS}"'"/' $CONFIG_DIR/config.toml
    sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.025u'"${DENOM}"'"/' $CONFIG_DIR/app.toml
    sed -i '0,/enable = false/s//enable = true/g' $CONFIG_DIR/app.toml
    sed -i '0,/swagger = false/s//swagger = false/g' $CONFIG_DIR/app.toml
    sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \["*"\]/' $CONFIG_DIR/config.toml
    sed -i 's/create_empty_blocks = true/create_empty_blocks = false/' $CONFIG_DIR/config.toml
    sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_propose =.*$/timeout_propose = "300ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_propose_delta =.*$/timeout_propose_delta = "100ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_prevote =.*$/timeout_prevote = "300ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_prevote_delta =.*$/timeout_prevote_delta = "100ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_precommit =.*$/timeout_precommit = "300ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_precommit_delta =.*$/timeout_precommit_delta = "100ms"/' $CONFIG_DIR/config.toml
    sed -i 's/^timeout_commit =.*$/timeout_commit = "1s"/' $CONFIG_DIR/config.toml
    sed -i 's/^snapshot-interval =.*$/snapshot-interval = 1000/' $CONFIG_DIR/app.toml

#    import mnemonic generated by the genesis validator (have a local copy for ease of use)
    echo $MNEMONIC | base64 -d > $HOME_DIR/mnemonic
     { cat $HOME_DIR/mnemonic; echo "${PASSPHRASE}"; echo "${PASSPHRASE}"; } | $BINARY_NAME keys add validator --recover #> /dev/null
    #$BINARY_NAME validate-genesis > /dev/null


        #if [ -z ${VALIDATOR_PRIV_KEY+x} ]; then 
        #    echo "Creating validator";
        #    { echo "${PASSPHRASE}"; sleep 10; yes; sleep 10; } | $BINARY_NAME tx staking create-validator --amount=10000000u"${STAKE_DENOM}" --fees 100000u"${DENOM}" --pubkey="$($BINARY_NAME tendermint show-validator)" --moniker="${MONIKER}" --commission-rate="${COMMISSION_RATE}" --commission-max-rate="0.20" --commission-max-change-rate="0.01" --min-self-delegation="1" --chain-id=$CHAIN_ID --from=validator -b async --node "${REMOTE_RPC_NODE}" > /validator_info
        #else 
        #    echo "Importing validator key";  
        #    echo  $VALIDATOR_PRIV_KEY |base64 -d > $CONFIG_DIR//priv_validator_key.json   
        #fi
        #  don't even ask about those sleeps...
        
        
        STATE_SYNC_RPC=$REMOTE_RPC_NODE
        STATE_SYNC_PEER=$PERSISTENT_PEERS
        LATEST_HEIGHT=$(curl -s $STATE_SYNC_RPC/block | jq -r .result.block.header.height)
        SYNC_BLOCK_HEIGHT=$(($LATEST_HEIGHT - 2000))
        SYNC_BLOCK_HASH=$(curl -s "$STATE_SYNC_RPC/block?height=$SYNC_BLOCK_HEIGHT" | jq -r .result.block_id.hash)
        
        sed -i.bak -e "s|^enable *=.*|enable = true|" $CONFIG_DIR/config.toml
        sed -i.bak -e "s|^rpc_servers *=.*|rpc_servers = \"$STATE_SYNC_RPC,$STATE_SYNC_RPC\"|" \
          $CONFIG_DIR/config.toml
        sed -i.bak -e "s|^trust_height *=.*|trust_height = $SYNC_BLOCK_HEIGHT|" \
          $CONFIG_DIR/config.toml
        sed -i.bak -e "s|^trust_hash *=.*|trust_hash = \"$SYNC_BLOCK_HASH\"|" \
          $CONFIG_DIR/config.toml
        #sed -i.bak -e "s|^persistent_peers *=.*|persistent_peers = \"$STATE_SYNC_PEER\"|" \
        #  $CONFIG_DIR/config.toml


        
  else
    echo "Validator already initialized, starting with the existing configuration."
    echo "If you want to re-init the validator, destroy the existing container"
  fi
  $BINARY_NAME tendermint unsafe-reset-all --keep-addr-book
	$BINARY_NAME start
else
	echo "Wrong command. Usage: ./$0 [genesis/validator]"
fi
