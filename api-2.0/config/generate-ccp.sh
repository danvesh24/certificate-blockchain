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
P0PORT=13051
CAPORT=13054
PEERPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/tlscacerts/tls-localhost-13054-ca-superadmin-certs-com.pem
CAPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/superadmin.certs.com/msp/tlscacerts/ca.crt

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $low_org)" > connection-superadmin.json


ORG="Company"
low_org="company"
P0PORT=15051
CAPORT=14054
PEERPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/tlscacerts/tls-localhost-14054-ca-company-certs-com.pem
CAPEM=../../blockchain/artifacts/channel/crypto-config/peerOrganizations/company.certs.com/msp/tlscacerts/ca.crt

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $low_org)" > connection-company.json


echo " -------------------- Conncetion Profile Generated ----------------------- "