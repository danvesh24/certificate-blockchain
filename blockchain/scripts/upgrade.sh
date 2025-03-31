#!/bin/bash
# filepath: /home/bishesh/cert/blockchain/scripts/upgrade.sh
#!/bin/bash
# imports
. enVar.sh
. utils.sh

# Variables
CHANNEL_NAME="mychannel"
CHAINCODE_NAME="Certificate"
CHAINCODE_VERSION="2.0"
CHAINCODE_PATH="../artifacts/src/github.com/chaincodes/go/Product/"
ORDERER_ADDRESS="orderer.certs.com:13050"
PEER_CONTAINER_NAME="peer0.superadmin.certs.com"
PEER_HOSTNAME="peer0.superadmin.certs.com"
CORE_PEER_LOCALMSPID="SuperadminMSP"
CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SUPERADMIN_CA
CORE_PEER_MSPCONFIGPATH=${PWD}/../artifacts/channel/crypto-config/peerOrganizations/superadmin.certs.com/users/Admin@superadmin.certs.com/msp
ORDERER_CA=${PWD}/../artifacts/channel/crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

echo "Upgrading chaincode on channel '$CHANNEL_NAME'"

# Check if the peer container is running
if [ ! "$(docker ps -q -f name=$PEER_CONTAINER_NAME)" ]; then
    echo "Error: Peer container '$PEER_CONTAINER_NAME' is not running."
    exit 1
fi

# Ensure the hostname is resolvable within the Docker network
docker exec $PEER_CONTAINER_NAME sh -c "echo '127.0.0.1 $PEER_HOSTNAME' >> /etc/hosts"

# Set environment variables for the peer
export CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID
export CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE
export CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH
export CORE_PEER_ADDRESS=$PEER_HOSTNAME:13051

# Install new chaincode version on peer
peer chaincode install -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -p $CHAINCODE_PATH

# Upgrade chaincode on channel
peer chaincode upgrade -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA \
    -C $CHANNEL_NAME -n $CHAINCODE_NAME -v $CHAINCODE_VERSION \
    -P "OR ('SuperadminMSP.peer','CompanyMSP.peer')"

echo "Chaincode upgraded successfully"