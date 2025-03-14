#!/bin/bash

# imports
. enVar.sh
. utils.sh

# Function to vendor Go dependencies for Product, Company, and Customer chaincodes
presetup() {
    echo "Vendoring Go dependencies for Product, Company, and Customer chaincodes..."
    
    # Product Chaincode
    pushd ../artifacts/src/github.com/chaincodes/go/Product/
    go mod init github.com/chaincodes/go/Product
    go mod tidy 
    GO111MODULE=on go mod vendor
    popd

    # Company Chaincode
    pushd ../artifacts/src/github.com/chaincodes/go/Company/
    go mod init github.com/chaincodes/go/Company
    go mod tidy 
    GO111MODULE=on go mod vendor
    popd

    # Customer Chaincode
    pushd ../artifacts/src/github.com/chaincodes/go/Customer/
    go mod init github.com/chaincodes/go/Customer
    go mod tidy 
    GO111MODULE=on go mod vendor
    popd

    # Batch Chaincode
    pushd ../artifacts/src/github.com/chaincodes/go/Batch/
    go mod init github.com/chaincodes/go/Batch
    go mod tidy 
    GO111MODULE=on go mod vendor
    popd

    echo "Finished vendoring Go dependencies for Product, Company, and Customer chaincodes"
}

# Chaincode variables
CC_NAME_2="Certificate"
CC_SRC_PATH_2="../artifacts/src/github.com/chaincodes/go/Product/"
CC_POLICY_2="OR('SuperadminMSP.peer','CompanyMSP.peer')"
CC_RUNTIME_LANGUAGE_2="golang"
VERSION_2="1"
SEQUENCE_2=1

CC_NAME_3="Company"
CC_SRC_PATH_3="../artifacts/src/github.com/chaincodes/go/Company/"
CC_POLICY_3="OR('SuperadminMSP.peer','CompanyMSP.peer')"
CC_RUNTIME_LANGUAGE_3="golang"
VERSION_3="1"
SEQUENCE_3=1

CC_NAME_4="Customer"
CC_SRC_PATH_4="../artifacts/src/github.com/chaincodes/go/Customer/"
CC_POLICY_4="OR('SuperadminMSP.peer','CompanyMSP.peer')"
CC_RUNTIME_LANGUAGE_4="golang"
VERSION_4="1"
SEQUENCE_4=1

CC_NAME_5="Batch"
CC_SRC_PATH_5="../artifacts/src/github.com/chaincodes/go/Batch/"
CC_POLICY_5="OR('SuperadminMSP.peer','CompanyMSP.peer')"
CC_RUNTIME_LANGUAGE_5="golang"
VERSION_5="1"
SEQUENCE_5=1

CHANNEL_NAME="mychannel"

# Package Chaincodes
packageChaincode() {
    # For ProductItem Chaincode
    rm -rf ${CC_NAME_2}.tar.gz
    peer lifecycle chaincode package ${CC_NAME_2}.tar.gz \
        --path ${CC_SRC_PATH_2} --lang ${CC_RUNTIME_LANGUAGE_2} \
        --label ${CC_NAME_2}_${VERSION_2}

    # For Company Chaincode
    rm -rf ${CC_NAME_3}.tar.gz
    peer lifecycle chaincode package ${CC_NAME_3}.tar.gz \
        --path ${CC_SRC_PATH_3} --lang ${CC_RUNTIME_LANGUAGE_3} \
        --label ${CC_NAME_3}_${VERSION_3}

    # For Customer Chaincode
    rm -rf ${CC_NAME_4}.tar.gz
    peer lifecycle chaincode package ${CC_NAME_4}.tar.gz \
        --path ${CC_SRC_PATH_4} --lang ${CC_RUNTIME_LANGUAGE_4} \
        --label ${CC_NAME_4}_${VERSION_4}
    
    rm -rf ${CC_NAME_5}.tar.gz
    peer lifecycle chaincode package ${CC_NAME_5}.tar.gz \
        --path ${CC_SRC_PATH_5} --lang ${CC_RUNTIME_LANGUAGE_5} \
        --label ${CC_NAME_5}_${VERSION_5}

    if [ $? -ne 0 ]; then
        echo "Error packaging chaincodes"
        exit 1
    fi
    echo "===================== Chaincodes packaged ===================== "
}

# Install Chaincodes
installChaincode() {
    # For Org1, ProductItem Chaincode
    setGlobals 1
    peer lifecycle chaincode install ${CC_NAME_2}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing productitem chaincode"
        exit 1
    fi
    echo "===================== Productitem chaincode installed ===================== "

    # For Org2, ProductItem Chaincode
    setGlobals 2
    peer lifecycle chaincode install ${CC_NAME_2}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing productitem chaincode on Org2"
        exit 1
    fi
    echo "===================== Productitem chaincode installed on peer0.company ===================== "

    # For Org1, Company Chaincode
    setGlobals 1
    peer lifecycle chaincode install ${CC_NAME_3}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing company chaincode"
        exit 1
    fi
    echo "===================== Company chaincode installed ===================== "

    # For Org2, Company Chaincode
    setGlobals 2
    peer lifecycle chaincode install ${CC_NAME_3}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing company chaincode on Org2"
        exit 1
    fi
    echo "===================== Company chaincode installed on peer0.company ===================== "

    # For Org1, Customer Chaincode
    setGlobals 1
    peer lifecycle chaincode install ${CC_NAME_4}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing customer chaincode"
        exit 1
    fi
    echo "===================== Customer chaincode installed ===================== "

    # For Org2, Customer Chaincode
    setGlobals 2
    peer lifecycle chaincode install ${CC_NAME_4}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing customer chaincode on Org2"
        exit 1
    fi
    echo "===================== Customer chaincode installed on peer0.company ===================== "

    setGlobals 1
    peer lifecycle chaincode install ${CC_NAME_5}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing Batch chaincode"
        exit 1
    fi
    echo "===================== Batch chaincode installed ===================== "

    # For Org2, Customer Chaincode
    setGlobals 2
    peer lifecycle chaincode install ${CC_NAME_5}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing Batch chaincode on Org2"
        exit 1
    fi
}

# Query Installed Chaincodes
queryInstalled() {
    setGlobals 1
    peer lifecycle chaincode queryinstalled >&log.txt
    cat log.txt
    PACKAGE_ID_2=$(sed -n "/${CC_NAME_2}_${VERSION_2}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    PACKAGE_ID_3=$(sed -n "/${CC_NAME_3}_${VERSION_3}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    PACKAGE_ID_4=$(sed -n "/${CC_NAME_4}_${VERSION_4}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    PACKAGE_ID_5=$(sed -n "/${CC_NAME_5}_${VERSION_5}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
    echo "===================== Query installed successful ===================== "
}

# Approve Chaincodes for Org1
approveForMyOrg1() {
    # Approve ProductItem Chaincode for Org1
    setGlobals 1
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_2} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_2} --version ${VERSION_2} \
        --package-id ${PACKAGE_ID_2} \
        --sequence ${SEQUENCE_2}
        

    # Approve Company Chaincode for Org1
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_3} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_3} --version ${VERSION_3} \
        --package-id ${PACKAGE_ID_3} \
        --sequence ${SEQUENCE_3}

    # Approve Customer Chaincode for Org1
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_4} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_4} --version ${VERSION_4} \
        --package-id ${PACKAGE_ID_4} \
        --sequence ${SEQUENCE_4}

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_5} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_5} --version ${VERSION_5} \
        --package-id ${PACKAGE_ID_5} \
        --sequence ${SEQUENCE_5}

    if [ $? -ne 0 ]; then
        echo "Error approving chaincodes for Org1"
        exit 1
    fi
    echo "===================== Chaincodes approved by SuperAdmin ===================== "
}

checkCommitReadyness() {
    setGlobals 1

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --signature-policy ${CC_POLICY_2} \
        --name ${CC_NAME_2} --version ${VERSION_2} --sequence ${SEQUENCE_2} --output json 
    echo "===================== checking commit readyness from Productitem ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --signature-policy ${CC_POLICY_3} \
        --name ${CC_NAME_3} --version ${VERSION_3} --sequence ${SEQUENCE_3} --output json 
    echo "===================== checking commit readyness from Company ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --signature-policy ${CC_POLICY_4} \
        --name ${CC_NAME_4} --version ${VERSION_4} --sequence ${SEQUENCE_4} --output json 

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --signature-policy ${CC_POLICY_5} \
        --name ${CC_NAME_5} --version ${VERSION_5} --sequence ${SEQUENCE_5} --output json

    echo "===================== checking commit readyness from Customer ===================== "

}

# Approve Chaincodes for Org2
approveForMyOrg2() {
    setGlobals 2

    # Approve ProductItem Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_2} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_2} \
        --version ${VERSION_2} --package-id ${PACKAGE_ID_2} \
        --sequence ${SEQUENCE_2}

    # Approve Company Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_3} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_3} \
        --version ${VERSION_3} --package-id ${PACKAGE_ID_3} \
        --sequence ${SEQUENCE_3}

    # Approve Customer Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_4} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_4} \
        --version ${VERSION_4} --package-id ${PACKAGE_ID_4} \
        --sequence ${SEQUENCE_4}

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.certs.com --tls \
        --signature-policy ${CC_POLICY_5} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_5} \
        --version ${VERSION_5} --package-id ${PACKAGE_ID_5} \
        --sequence ${SEQUENCE_5}

    if [ $? -ne 0 ]; then
        echo "Error approving chaincodes for Org2"
        exit 1
    fi
    echo "===================== Chaincodes approved by Company ===================== "
}

checkCommitReadyness() {
    setGlobals 2

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --signature-policy ${CC_POLICY_2} \
        --name ${CC_NAME_2} --version ${VERSION_2} --sequence ${SEQUENCE_2} --output json 
    echo "===================== checking commit readyness from Productitem ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --signature-policy ${CC_POLICY_3} \
        --name ${CC_NAME_3} --version ${VERSION_3} --sequence ${SEQUENCE_3} --output json 
    echo "===================== checking commit readyness from Company ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --signature-policy ${CC_POLICY_4} \
        --name ${CC_NAME_4} --version ${VERSION_4} --sequence ${SEQUENCE_4} --output json 
    
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --signature-policy ${CC_POLICY_5} \
        --name ${CC_NAME_5} --version ${VERSION_5} --sequence ${SEQUENCE_5} --output json 
    echo "===================== checking commit readyness from Customer ===================== "
}


# Commit Chaincodes
commitChaincodeDefination() {
    setGlobals 1
    # Commit ProductItem Chaincode
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.certs.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_2} \
        --signature-policy ${CC_POLICY_2} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --version ${VERSION_2} --sequence ${SEQUENCE_2}

    # Commit Company Chaincode
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.certs.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_3} \
        --signature-policy ${CC_POLICY_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --version ${VERSION_3} --sequence ${SEQUENCE_3}

    # Commit Customer Chaincode
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.certs.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_4} \
        --signature-policy ${CC_POLICY_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --version ${VERSION_4} --sequence ${SEQUENCE_4}

    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.certs.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_5} \
        --signature-policy ${CC_POLICY_5} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --version ${VERSION_5} --sequence ${SEQUENCE_5}

    if [ $? -ne 0 ]; then
        echo "Error committing chaincodes"
        exit 1
    fi
    echo "===================== Chaincodes committed ===================== "
}

# Query committed chaincodes
queryCommitted() {
    setGlobals 1
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME
    echo "===================== Query committed chaincodes ===================== "
}



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


