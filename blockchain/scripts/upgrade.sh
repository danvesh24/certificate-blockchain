#!/bin/bash

# imports
. enVar.sh
. utils.sh

# Prompt user for CC_NAME, VERSION, and SEQUENCE only if not running viewVersion
if [[ "$1" != "viewVersion" ]]; then
    read -p "Enter the Chaincode Name (CC_NAME): " CC_NAME
    read -p "Enter the Chaincode Version (VERSION): " VERSION
    read -p "Enter the Chaincode Sequence (SEQUENCE): " SEQUENCE
fi

CC_SRC_PATH="../artifacts/src/github.com/chaincodes/go/$CC_NAME/"
CC_POLICY="OR('SuperadminMSP.peer','CompanyMSP.peer')"
CC_RUNTIME_LANGUAGE="golang"
CHANNEL_NAME="mychannel"

viewVersion() {
    setGlobals 1
    echo "Querying committed chaincodes for channel: $CHANNEL_NAME"
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME >&log.txt
    cat log.txt
    CURRENT_VERSION=$(grep "Version:" log.txt | awk '{print $2}')
    echo "===================== Current Version of $CC_NAME: $CURRENT_VERSION ====================="
}

# Function to vendor Go dependencies for Certificate, Company, and Customer chaincodes
presetup() {
    echo "Vendoring Go dependencies for Certificate, Company, and Customer chaincodes..."

    # HealthCard Chaincode
    pushd ../artifacts/src/github.com/chaincodes/go/$CC_NAME/
    go mod init github.com/chaincodes/go/$CC_NAME
    go mod tidy 
    GO111MODULE=on go mod vendor
    popd

    echo "Finished vendoring Go dependencies for Certificate, Company, and Customer chaincodes"
}


# Package Chaincodes
packageChaincode() {

    # For HealthCard Chaincode
    rm -rf ${CC_NAME}.tar.gz
    peer lifecycle chaincode package ${CC_NAME}.tar.gz \
        --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
        --label ${CC_NAME}_${VERSION}

    if [ $? -ne 0 ]; then
        echo "Error packaging chaincodes"
        exit 1
    fi
    echo "===================== Chaincodes packaged ===================== "
}

# Install Chaincodes
installChaincode() {

    # For Org1, HealthCard Chaincode
    setGlobals 1
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing HealthCard chaincode"
        exit 1
    fi
    echo "===================== HealthCard chaincode installed ===================== "

    # For Org2, HealthCard Chaincode
    setGlobals 2
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing HealthCard chaincode on Org2"
        exit 1
    fi
    echo "===================== HealthCard chaincode installed on peer0.company ===================== "

}

# Query Installed Chaincodes
queryInstalled() {
    setGlobals 1
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID_6=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo "===================== Query installed successful ===================== "
}

# Approve Chaincodes for Org1
approveForMyOrg1() {
   

    # Approve HealthCard Chaincode for Org1
    peer lifecycle chaincode approveformyorg -o localhost:13050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
        --package-id ${PACKAGE_ID_6} \
        --sequence ${SEQUENCE}

    if [ $? -ne 0 ]; then
        echo "Error approving chaincodes for Org1"
        exit 1
    fi
    echo "===================== Chaincodes approved by SuperAdmin ===================== "
}

checkCommitReadyness() {
    setGlobals 1

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --signature-policy ${CC_POLICY} \
        --name ${CC_NAME} --version ${VERSION} --sequence ${SEQUENCE} --output json
    echo "===================== checking commit readyness from HealthCard ===================== "

    echo "===================== checking commit readyness from Customer ===================== "

}

# Approve Chaincodes for Org2
approveForMyOrg2() {
    setGlobals 2

    # Approve HealthCard Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:13050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --version ${VERSION} --package-id ${PACKAGE_ID_6} \
        --sequence ${SEQUENCE}

    if [ $? -ne 0 ]; then
        echo "Error approving chaincodes for Org2"
        exit 1
    fi
    echo "===================== Chaincodes approved by Company ===================== "
}

checkCommitReadyness() {
    setGlobals 2

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:15051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --signature-policy ${CC_POLICY} \
        --name ${CC_NAME} --version ${VERSION} --sequence ${SEQUENCE} --output json 
    echo "===================== checking commit readyness from HealthCard ===================== "
}


# Commit Chaincodes
commitChaincodeDefination() {
    setGlobals 1

    # Commit HealthCard Chaincode
    peer lifecycle chaincode commit -o localhost:13050 --ordererTLSHostnameOverride orderer.certs.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME} \
        --signature-policy ${CC_POLICY} \
        --peerAddresses localhost:13051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:15051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --version ${VERSION} --sequence ${SEQUENCE}

    if [ $? -ne 0 ]; then
        echo "Error committing chaincodes"
        exit 1
    fi
    echo "===================== Chaincodes committed ===================== "
}

# Query committed chaincodes
queryCommitted() {
    setGlobals 1
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME
    echo "===================== Query committed chaincodes ===================== "
}

if [[ "$1" == "viewVersion" ]]; then
    read -p "Enter the Chaincode Name (CC_NAME): " CC_NAME
    viewVersion
    exit 0
fi

#Execute the functions
presetup
packageChaincode
installChaincode
queryInstalled
approveForMyOrg1
checkCommitReadyness
approveForMyOrg2
checkCommitReadyness
commitChaincodeDefination
queryCommitted


