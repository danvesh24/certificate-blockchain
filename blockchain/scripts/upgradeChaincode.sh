#!/bin/bash

# Load environment variables and utility functions
. enVar.sh
. utils.sh

# Chaincode details
declare -A chaincodes=(
    ["Productitem"]="../artifacts/src/github.com/chaincodes/go/Product/,golang,OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
    # ["Company"]="../artifacts/src/github.com/chaincodes/go/Company/,golang,OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
    # ["Customer"]="../artifacts/src/github.com/chaincodes/go/Customer/,golang,OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
    # ["Batch"]="../artifacts/src/github.com/chaincodes/go/Batch/,golang,OR('SuperadminMSP.peer','CompanyMSP.peer','RetailerMSP.peer')"
)

# Version tracking file
VERSION_FILE="chaincode_versions.txt"

# Get next version of the chaincode
getNextVersion() {
    local cc_name=$1
    local current_version=$(grep "^${cc_name}=" $VERSION_FILE | cut -d'=' -f2)
    if [ -z "$current_version" ]; then
        echo "1"
    else
        echo $((current_version + 1))
    fi
}

# Update version file
updateVersionFile() {
    local cc_name=$1
    local new_version=$2
    if grep -q "^${cc_name}=" $VERSION_FILE; then
        sed -i "s/^${cc_name}=.*/${cc_name}=${new_version}/" $VERSION_FILE
    else
        echo "${cc_name}=${new_version}" >> $VERSION_FILE
    fi
}

# Package chaincode
packageChaincode() {
    local cc_name=$1
    local cc_path=$2
    local cc_version=$3
    echo "Packaging chaincode $cc_name..."
    pushd $cc_path > /dev/null
    go mod tidy
    GO111MODULE=on go mod vendor
    popd > /dev/null
    peer lifecycle chaincode package ${cc_name}.tar.gz \
        --path $cc_path --lang golang \
        --label ${cc_name}_${cc_version}
    echo "Chaincode $cc_name version $cc_version packaged."
}

# Install chaincode
installChaincode() {
    local cc_name=$1
    local cc_version=$2
    echo "Installing chaincode $cc_name..."
    
    # Loop over organizations 1 to 3
    for org in {1..3}; do
        setGlobals $org
        peer lifecycle chaincode install ${cc_name}.tar.gz
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install chaincode $cc_name for Org${org}. Exiting."
            exit 1
        fi
    done
    echo "Chaincode $cc_name version $cc_version installed successfully on all organizations."
}

# Query installed chaincode
queryInstalled() {
    local cc_name=$1
    local cc_version=$2
    echo "Querying installed chaincodes for $cc_name..."
    setGlobals 1
    peer lifecycle chaincode queryinstalled >&log.txt
    PACKAGE_ID=$(grep "${cc_name}_${cc_version}" log.txt | awk -F ', ' '{print $1}' | awk -F ': ' '{print $2}')
    if [ -z "$PACKAGE_ID" ]; then
        echo "Error: Could not retrieve Package ID for $cc_name version $cc_version. Exiting."
        exit 1
    fi
    echo "Package ID for chaincode $cc_name version $cc_version: $PACKAGE_ID"
}

# Approve chaincode
approveChaincode() {
    local cc_name=$1
    local cc_version=$2
    local cc_sequence=$3
    local cc_policy=$4
    local package_id=$5
    echo "Approving chaincode $cc_name..."
    
    # Loop over organizations 1 to 3
    for org in {1..3}; do
        setGlobals $org
        peer lifecycle chaincode approveformyorg -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.productauth.com --tls \
        --signature-policy $cc_policy \
        --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name $cc_name \
        --version $cc_version --package-id $package_id \
        --sequence $cc_sequence
        if [ $? -ne 0 ]; then
            echo "Error: Approval for chaincode $cc_name by Org${org} failed. Exiting."
            exit 1
        fi
    done
    echo "Chaincode $cc_name version $cc_version approved by all organizations."
}

# Commit chaincode
commitChaincode() {
    local cc_name=$1
    local cc_version=$2
    local cc_sequence=$3
    local cc_policy=$4
    echo "Committing chaincode $cc_name..."
    
    # Set global variables for Org1
    setGlobals 1
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_COMPANY_CA \
        --signature-policy $cc_policy \
        --name $cc_name --version $cc_version --sequence $cc_sequence --output json
    if [ $? -ne 0 ]; then
        echo "Error: Commit for chaincode $cc_name failed. Exiting."
        exit 1
    fi
    echo "Chaincode $cc_name committed successfully."
}

# Main logic to handle all chaincodes
CHANNEL_NAME="mychannel"

# Step 1: Package and install all chaincodes
for cc_name in "${!chaincodes[@]}"; do
    IFS=',' read -r cc_path cc_language cc_policy <<< "${chaincodes[$cc_name]}"
    cc_version=$(getNextVersion $cc_name)
    packageChaincode $cc_name $cc_path $cc_version
    installChaincode $cc_name $cc_version
done

# Step 2: Query, approve, and commit all chaincodes
for cc_name in "${!chaincodes[@]}"; do
    IFS=',' read -r cc_path cc_language cc_policy <<< "${chaincodes[$cc_name]}"
    cc_version=$(getNextVersion $cc_name)
    queryInstalled $cc_name $cc_version
    approveChaincode $cc_name $cc_version $cc_version "$cc_policy" $PACKAGE_ID
    commitChaincode $cc_name $cc_version $cc_version "$cc_policy"
    updateVersionFile $cc_name $cc_version
done