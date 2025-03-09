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
CC_POLICY_2="OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
CC_RUNTIME_LANGUAGE_2="golang"
VERSION_2="1"
SEQUENCE_2=1

CC_NAME_3="Company"
CC_SRC_PATH_3="../artifacts/src/github.com/chaincodes/go/Company/"
CC_POLICY_3="OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
CC_RUNTIME_LANGUAGE_3="golang"
VERSION_3="1"
SEQUENCE_3=1

CC_NAME_4="Customer"
CC_SRC_PATH_4="../artifacts/src/github.com/chaincodes/go/Customer/"
CC_POLICY_4="OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
CC_RUNTIME_LANGUAGE_4="golang"
VERSION_4="1"
SEQUENCE_4=1

CC_NAME_5="Batch"
CC_SRC_PATH_5="../artifacts/src/github.com/chaincodes/go/Batch/"
CC_POLICY_5="OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
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

    # For Org2, ProductItem Chaincode
    setGlobals 3
    peer lifecycle chaincode install ${CC_NAME_2}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing productitem chaincode on Org3"
        exit 1
    fi
    echo "===================== Productitem chaincode installed on peer0.retailer ===================== "

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

    setGlobals 3
    peer lifecycle chaincode install ${CC_NAME_3}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing company chaincode on Org3"
        exit 1
    fi
    echo "===================== Company chaincode installed on peer0.retailer ===================== "

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

    setGlobals 3
    peer lifecycle chaincode install ${CC_NAME_4}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing customer chaincode on Org3"
        exit 1
    fi
        echo "===================== Customer chaincode installed on peer0.retailer ===================== "


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

    setGlobals 3
    peer lifecycle chaincode install ${CC_NAME_5}.tar.gz
    if [ $? -ne 0 ]; then
        echo "Error installing Batch chaincode on Org2"
        exit 1
    fi
    echo "===================== Customer chaincode Installed ===================== "
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
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_2} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_2} --version ${VERSION_2} \
        --package-id ${PACKAGE_ID_2} \
        --sequence ${SEQUENCE_2}
        

    # Approve Company Chaincode for Org1
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_3} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_3} --version ${VERSION_3} \
        --package-id ${PACKAGE_ID_3} \
        --sequence ${SEQUENCE_3}

    # Approve Customer Chaincode for Org1
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_4} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_4} --version ${VERSION_4} \
        --package-id ${PACKAGE_ID_4} \
        --sequence ${SEQUENCE_4}

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
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
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_2} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_2} \
        --version ${VERSION_2} --package-id ${PACKAGE_ID_2} \
        --sequence ${SEQUENCE_2}

    # Approve Company Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_3} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_3} \
        --version ${VERSION_3} --package-id ${PACKAGE_ID_3} \
        --sequence ${SEQUENCE_3}

    # Approve Customer Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_4} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_4} \
        --version ${VERSION_4} --package-id ${PACKAGE_ID_4} \
        --sequence ${SEQUENCE_4}

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
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

approveForMyOrg3() {
    setGlobals 3

    # Approve ProductItem Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_2} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_2} \
        --version ${VERSION_2} --package-id ${PACKAGE_ID_2} \
        --sequence ${SEQUENCE_2}

    # Approve Company Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_3} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_3} \
        --version ${VERSION_3} --package-id ${PACKAGE_ID_3} \
        --sequence ${SEQUENCE_3}

    # Approve Customer Chaincode for Org2
    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy ${CC_POLICY_4} \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME_4} \
        --version ${VERSION_4} --package-id ${PACKAGE_ID_4} \
        --sequence ${SEQUENCE_4}

    peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
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

checkCommitReadyness(){
    setGlobals 3

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --signature-policy ${CC_POLICY_2} \
        --name ${CC_NAME_2} --version ${VERSION_2} --sequence ${SEQUENCE_2} --output json 
    echo "===================== checking commit readyness from Productitem ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --signature-policy ${CC_POLICY_3} \
        --name ${CC_NAME_3} --version ${VERSION_3} --sequence ${SEQUENCE_3} --output json 
    echo "===================== checking commit readyness from Company ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --signature-policy ${CC_POLICY_4} \
        --name ${CC_NAME_4} --version ${VERSION_4} --sequence ${SEQUENCE_4} --output json 
    echo "===================== checking commit readyness from Customer ===================== "

    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --signature-policy ${CC_POLICY_5} \
        --name ${CC_NAME_5} --version ${VERSION_5} --sequence ${SEQUENCE_5} --output json 
    echo "===================== checking commit readyness from Batch ===================== "

}

# Commit Chaincodes
commitChaincodeDefination() {
    setGlobals 1
    # Commit ProductItem Chaincode
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.productauth.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_2} \
        --signature-policy ${CC_POLICY_2} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --version ${VERSION_2} --sequence ${SEQUENCE_2}

    # Commit Company Chaincode
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.productauth.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_3} \
        --signature-policy ${CC_POLICY_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --version ${VERSION_3} --sequence ${SEQUENCE_3}

    # Commit Customer Chaincode
    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.productauth.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_4} \
        --signature-policy ${CC_POLICY_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        --version ${VERSION_4} --sequence ${SEQUENCE_4}

    peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.productauth.com \
        --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA \
        --channelID $CHANNEL_NAME --name ${CC_NAME_5} \
        --signature-policy ${CC_POLICY_5} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
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


checkcustomer() {
    setGlobals 2  # Set environment variables for Org2

    # Create the first customer "John Doe"
    echo "Creating customer John Doe"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateCustomer","Args":["John Doe","john.doe@productauth.com","+1234567890","AcmeCorp","Water","John Smith","ORD1001"]}'

    # Wait for transaction to be committed
    sleep 5
    echo "Querying customer John Doe"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_4} -c '{"function":"QueryCustomer","Args":["John Doe"]}'

    # Create the second customer "Alice Smith"
    echo "Creating customer Alice Smith"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateCustomer","Args":["Alice Smith","alice.smith@productauth.com","+0987654321","TechSolutions","Software, Hardware","Bob Green","ORD1002"]}'

    # Wait for transaction to be committed
    sleep 5
    echo "Querying customer Alice Smith"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_4} -c '{"function":"QueryCustomer","Args":["Alice Smith"]}'

    # Edit customer "John Doe", updating some fields
    echo "Editing customer John Doe"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"EditCustomer","Args":["John Doe", "Johnny Doe", "johnny.doe@productauth.com", "+1122334455"]}'

    # Wait for transaction to be committed
    sleep 5
    echo "Querying customer Johnny Doe after editing"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_4} -c '{"function":"QueryCustomer","Args":["Johnny Doe"]}'

    # Edit customer "Alice Smith", updating some fields
    echo "Editing customer Alice Smith"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"EditCustomer","Args":["Alice Smith", "Alicia Smith", "alicia.smith@productauth.com", "+1122334455"]}'

    # Wait for transaction to be committed
    sleep 5
    echo "Querying customer Alicia Smith after editing"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_4} -c '{"function":"QueryCustomer","Args":["Alicia Smith"]}'

    sleep 5 

    # Retrieve customer data with hash for Alicia Smith
    echo "Fetching customer Alicia Smith with hash"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_4} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"GetCustomerWithHash","Args":["Alicia Smith"]}'
}


checkcompany() {
    setGlobals 2  # Set environment variables for Org2

    # 1. Create the first company "AcmeCorp" with a new valid ID
    echo "Creating company AcmeCorp"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateCompany","Args":["60d5b25f9a9b1f5b6b1f7c1d","AcmeCorp","12345","York","USA","1234 Elm St.","enabled","Good company","http://productauth.com/logo.png","John","Doe","john.doe@productauth.com","Password","+123456789012","company","[\"Water\"]","2024-11-25T12:00:00", "2024-11-25T12:00:00"]}'
    
    sleep 5
    echo "Querying AcmeCorp"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_3} -c '{"function":"QueryCompany","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # 2. Create the second company "TechSolutions" with a new valid ID
    echo "Creating company TechSolutions"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateCompany","Args":["6704c07f37d54fbca4a5644d","RamEstablishment","88992","ktm","Nepal","humlas","enabled","company","uploads\\profilePics\\file-1731314491919-430431490.jpg","Ramon","Prasads","ram@gmail.com","$2b$10$apTB03zgF1u.kqEs5X8Uf.iGSnDtFeRIotMQST8de8Fy8Gxmbk1U.","+123456789012","company","[\"Gloves\"]","2024-11-25T12:00:00", "2024-11-25T12:00:00"]}'

    sleep 5
    echo "Querying TechSolutions"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_3} -c '{"function":"QueryCompany","Args":["6704c07f37d54fbca4a5644d"]}'

    # 3. Change status of the first company (AcmeCorp) to Inactive
    echo "Changing status of AcmeCorp to Inactive"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"ChangeCompanyStatus","Args":["60d5b25f9a9b1f5b6b1f7c1d","disabled"]}'

    sleep 5
    echo "Querying AcmeCorp after status change"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_3} -c '{"function":"QueryCompany","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # 4. Edit company TechSolutions (corrected zip code and address values)
    echo "Editing company TechSolutions"
    peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.productauth.com \
    --tls --cafile $ORDERER_CA \
    -C $CHANNEL_NAME -n ${CC_NAME_3} \
    --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
    --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
    --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
    -c '{"function":"EditCompany","Args":["6704c07f37d54fbca4a5644d","TechSolutions", "10001", "Kathmandu", "Nepal", "Chabil", "Bob", "Green", "bob.green@productauth.com","+9876543210","Retailer","[\"Networking\"]"]}'

    sleep 5
    echo "Querying TechSolutions after editing"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_3} -c '{"function":"QueryCompany","Args":["6704c07f37d54fbca4a5644d"]}'

    sleep 5
    echo "Querying TechSolutions with hash"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"GetCompanyWithHash","Args":["5704c07f37d54fbca4a5644d"]}'
    sleep 5

    # 5. Create another instance of AcmeCorp for testing (with corrected values)
    echo "Creating another instance of AcmeCorp"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_3} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateCompany","Args":["60d5b25f9a9b1f5b6b1f7c1d","AcmeCorp","12345","York","USA","1234 Elm St.","enabled","Good company","http://productauth.com/logo.png","John","Doe","john.doe@productauth.com","Password","+123456789012","company","[\"Water\"]","2024-11-25T12:00:00", "2024-11-25T12:00:00"]}'

    sleep 5

    # 6. Query all companies
    echo "Querying all companies"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_3} -c '{"Args":["QueryAllCompanies"]}'

    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.productauth.com \
    #     --tls --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME_3} \
    #     --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
    #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
    #    --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
    #     -c '{"function":"DeleteCompany","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # Optionally, you can also add a command to get the history for all assets of a company
    # echo "Getting history for all assets of AcmeCorp"
    # peer chaincode invoke -o localhost:7050 \
    #     --ordererTLSHostnameOverride orderer.productauth.com \
    #     --tls --cafile $ORDERER_CA \
    #     -C $CHANNEL_NAME -n ${CC_NAME_3} \
    #     --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
    #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
    #     --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
    #     -c '{"function":"GetHistoryForAllAssetsOfCompany","Args":[]} '

}



checkproduct() {
    setGlobals 2  # Set environment variables for Org2

    # Create the first product "Product1"
    echo "Creating product Product1"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_2} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateProductItem","Args":["60d5b25f9a9b1f5b6b1f7c1d", 
            "Product A", 
            "Description of Product A", 
            "19.99", 
            "sku123", 
            "[{\"_id\":\"60e4c7f8876e5e35b8817c1f\", \"batchId\":\"Batch A\"}]", 
            "Available", 
            "[{\"_id\":\"60e4c7f8876e5e35b8817c20\",\"name\":\"Electronics\"}]", 
            "[{\"_id\":\"60e4c7f8876e5e35b8817c21\",\"companyName\":\"TechCorp\"}]", 
            "[{\"attributeName\":\"Color\",\"attributeValue\":\"Red\"}]", 
            "slug-product", 
            "[\"image1.jpg\", \"image2.jpg\"]", 
            "http://productauth.com/product-a", 
            "2023-11-19T10:00:00Z", 
            "2023-11-19T10:01:00Z", 
            "meow meow qrl",
            "60e4c7f8876e5e35b8817c21"]}'
    # Wait for transaction to be committed
    sleep 5
    echo "Querying Product1"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_2} -c '{"function":"QueryProductItem","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # Create the second product "Product2"
    echo "Creating product Product2"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_2} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateProductItem","Args":["6704c07f37d54fbca4a5644d", 
            "Product B", 
            "Description of Product B", 
            "49.99", 
            "sku456", 
            "[{\"_id\":\"60e4c7f8876e5e35b8817c1f\", \"batchId\":\"Batch A\"}]", 
            "In Stock", 
            "[{\"_id\":\"6704c7f8f1a2b1e0d9f01c21\",\"name\":\"Home Appliances\"}]", 
            "[{\"_id\":\"6704c7f8f1a2b1e0d9f01c31\",\"companyName\":\"ApplianceCorp\"}]", 
            "[{\"attributeName\":\"Size\",\"attributeValue\":\"Large\"}]", 
            "slug-product-b", 
            "[\"image3.jpg\", \"image4.jpg\"]", 
            "http://productauth.com/product-b", 
            "2023-12-01T12:00:00Z", 
            "2023-12-01T12:01:00Z",
            "hello qrl", 
            "6704c7f8f1a2b1e0d9f01c21"]}'
    # Wait for transaction to be committed
    sleep 5
    echo "Querying Product2"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_2} -c '{"function":"QueryProductItem","Args":["6704c07f37d54fbca4a5644d"]}'

     # Edit product Product2, updating some fields
    echo "Editing product Product A"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_2} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"EditProductItem","Args":["60d5b25f9a9b1f5b6b1f7c1d", 
        "Updated Product A", 
        "Updated description for Product A", 
        "49.99", 
        "sku123", 
        "[{\"_id\":\"60e4c7f8876e5e35b8817c1f\",\"batchName\":\"Batch A\"}]", 
        "Available", 
        "[{\"_id\":\"60e4c7f8876e5e35b8817c20\",\"name\":\"Electronics\"}]", 
        "[{\"_id\":\"60e4c7f8876e5e35b8817c21\",\"companyName\":\"TechCorp\"}]", 
        "[{\"attributeName\":\"Color\", \"attributeValue\":\"Red\"}]", 
        "updated-product-slug", 
        "[\"image_updated1.jpg\", \"image_updated2.jpg\"]", 
        "http://productauth.com/updated-product-a"]}'
    
    # Wait for transaction to be committed
    echo "Waiting for Product A edit to be committed"
    sleep 5
    echo "Querying Product A after editing"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_2} -c '{"function":"QueryProductItem","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # Fetch Product with hash
    echo "Fetching Product with hash for Product A"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_2} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"GetProductWithHash","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # Wait for completion
    echo "Waiting for final transaction to be completed"
    sleep 5
}

checkBatch() {
    setGlobals 2  # Set environment variables for Org2

    # Check for Batch1 
    echo "Creating Batch1"
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_5} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateBatch","Args":["60d5b25f9a9b1f5b6b1f7c1d","Batch1","60d5f2c8f1a2b1e0d9f01d10","2024-01-01","2024-01-02"]}'

    # Wait for transaction to be committed
    sleep 5

    echo "Querying Batch1 after creation"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_5} -c '{"function":"QueryBatch","Args":["60d5b25f9a9b1f5b6b1f7c1d"]}'

    # Create Batch2 
    echo "Creating Batch2 "
    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_5} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"CreateBatch","Args":["6704c07f37d54fbca4a5644d","Batch2","60d5f2c8f1a2b1e0d9f01d11","2024-02-01","2024-02-02"]}'

    # Wait for transaction to be committed
    sleep 5

    echo "Querying Batch2 after creation"
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME_5} -c '{"function":"QueryBatch","Args":["6704c07f37d54fbca4a5644d"]}'

    sleep 5

    peer chaincode invoke -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com \
        --tls --cafile $ORDERER_CA \
        -C $CHANNEL_NAME -n ${CC_NAME_5} \
        --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
        -c '{"function":"GetBatchWithHash","Args":["60d5b25f9a9b1f5b6b1f7c1d","6704c07f37d54fbca4a5644d"]}'

}


try() {

    setGlobals 2  # Set environment variables for Org2

        # 1. Create the first company "AcmeCorp" with a new valid ID
        echo "Creating company AcmeCorp"
        peer chaincode invoke -o localhost:7050 \
            --ordererTLSHostnameOverride orderer.productauth.com \
            --tls --cafile $ORDERER_CA \
            -C $CHANNEL_NAME -n ${CC_NAME_3} \
            --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
            --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
            --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
            -c '{"function":"CreateCompany","Args":["60d5b25f9a9b1f5b6b1f7c2d","Acme","12345","York","USA","1234 Elm St.","enabled","Good company","http://productauth.com/logo.png","John","Doe","john.doe@productauth.com","Password","+123456789012","company","[\"Water\"]"]}'

    echo "Querying TechSolutions with hash"
        peer chaincode invoke -o localhost:7050 \
            --ordererTLSHostnameOverride orderer.productauth.com \
            --tls --cafile $ORDERER_CA \
            -C $CHANNEL_NAME -n ${CC_NAME_3} \
            --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_SUPERADMIN_CA \
            --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
            --peerAddresses localhost:10051 --tlsRootCertFiles $PEER0_RETAILER_CA \
            -c '{"function":"GetCompanyWithHash","Args":["60d5b2619a9b1f5b6b1f7c2e"]}'
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
approveForMyOrg3
checkCommitReadyness
commitChaincodeDefination
queryCommitted
# checkcustomer
# checkproduct
# checkcompany
# checkBatch
# try

