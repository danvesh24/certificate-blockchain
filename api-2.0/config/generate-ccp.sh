#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s#\${low_org}#$6#" \
        ./ccp-template.json
}

ORG="Superadmin"
low_org="superadmin"
P0PORT=7051
CAPORT=7054
PEERPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/tlscacerts/tls-localhost-7054-ca-superadmin-productauth-com.pem
CAPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/superadmin.productauth.com/msp/tlscacerts/ca.crt

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $low_org)" > connection-superadmin.json


ORG="Company"
low_org="company"
P0PORT=9051
CAPORT=8054
PEERPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/tlscacerts/tls-localhost-8054-ca-company-productauth-com.pem
CAPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/company.productauth.com/msp/tlscacerts/ca.crt

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $low_org)" > connection-company.json

ORG="Retailer"
low_org="retailer"
P0PORT=10051
CAPORT=10054
PEERPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/tlscacerts/tls-localhost-10054-ca-retailer-productauth-com.pem
CAPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/retailer.productauth.com/msp/tlscacerts/ca.crt

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $low_org)" > connection-retailer.json

echo " -------------------- Conncetion Profile Generated ----------------------- "