#!/bin/bash

# imports  
. enVar.sh
. utils.sh

CHANNEL_NAME='mychannel'

createChannel(){
    setGlobals 1
    osnadmin channel join --channelID $CHANNEL_NAME \
    --config-block ../channel-artifacts/${CHANNEL_NAME}.block -o localhost:13053 \
    --ca-file $ORDERER_CA \
    --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT \
    --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY 

    setGlobals 1
    osnadmin channel join --channelID $CHANNEL_NAME \
    --config-block ../channel-artifacts/${CHANNEL_NAME}.block -o localhost:14053 \
    --ca-file $ORDERER_CA \
    --client-cert $ORDERER2_ADMIN_TLS_SIGN_CERT \
    --client-key $ORDERER2_ADMIN_TLS_PRIVATE_KEY 

    setGlobals 1
    osnadmin channel join --channelID $CHANNEL_NAME \
    --config-block ../channel-artifacts/${CHANNEL_NAME}.block -o localhost:15053 \
    --ca-file $ORDERER_CA \
    --client-cert $ORDERER3_ADMIN_TLS_SIGN_CERT \
    --client-key $ORDERER3_ADMIN_TLS_PRIVATE_KEY 

}

createChannel

sleep 5

joinChannel(){ 
    sleep 3
    FABRIC_CFG_PATH=$PWD/../artifacts/channel/config
    setGlobals 1
    peer channel join -b ../channel-artifacts/${CHANNEL_NAME}.block

    sleep 3
    
    setGlobals 2
    peer channel join -b ../channel-artifacts/${CHANNEL_NAME}.block
    
}

joinChannel


# createChannel
# joinChannel
# setAnchorPeer