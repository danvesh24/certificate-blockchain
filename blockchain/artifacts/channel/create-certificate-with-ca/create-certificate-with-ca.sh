createcertificatesForsuperadmin() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/peerOrganizations/superadmin.certs.com/
  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca.superadmin.certs.com --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem
   

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-certs-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-certs-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-certs-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-certs-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/msp/config.yaml

  echo
  echo "Register peer0"
  echo
  fabric-ca-client register --caname ca.superadmin.certs.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  echo
  echo "Register user"
  echo
  fabric-ca-client register --caname ca.superadmin.certs.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  echo
  echo "Register the org admin"
  echo
  fabric-ca-client register --caname ca.superadmin.certs.com --id.name superadminadmin --id.secret superadminadminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/superadmin.certs.com/peers

  # -----------------------------------------------------------------------------------
  #  Peer 0
  mkdir -p ../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com

  echo
  echo "## Generate the peer0 msp"
  echo
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca.superadmin.certs.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/msp --csr.hosts peer0.superadmin.certs.com --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca.superadmin.certs.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls --enrollment.profile tls --csr.hosts peer0.superadmin.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/tlsca/tlsca.superadmin.certs.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/peers/peer0.superadmin.certs.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/ca/ca.superadmin.certs.com-cert.pem

  # --------------------------------------------------------------------------------------------------

  mkdir -p ../crypto-config/peerOrganizations/superadmin.certs.com/users
  mkdir -p ../crypto-config/peerOrganizations/superadmin.certs.com/users/User1@superadmin.certs.com

  echo
  echo "## Generate the user msp"
  echo
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca.superadmin.certs.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/User1@superadmin.certs.com/msp --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/User1@superadmin.certs.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/User1@superadmin.certs.com/msp/keystore/priv_sk
  mkdir -p ../crypto-config/peerOrganizations/superadmin.certs.com/users/Admin@superadmin.certs.com

  echo
  echo "## Generate the org admin msp"
  echo
  fabric-ca-client enroll -u https://superadminadmin:superadminadminpw@localhost:7054 --caname ca.superadmin.certs.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/Admin@superadmin.certs.com/msp --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/Admin@superadmin.certs.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/Admin@superadmin.certs.com/msp/keystore/priv_sk
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/superadmin.certs.com/users/Admin@superadmin.certs.com/msp/config.yaml

}

# createcertificatesForsuperadmin

createCertificatesForcompany() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p /../crypto-config/peerOrganizations/company.certs.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/company.certs.com/

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca.company.certs.com --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-certs-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-certs-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-certs-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-certs-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/company.certs.com/msp/config.yaml

  echo
  echo "Register peer0"
  echo
   
  fabric-ca-client register --caname ca.company.certs.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  echo
  echo "Register user"
  echo
   
  fabric-ca-client register --caname ca.company.certs.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  echo
  echo "Register the org admin"
  echo
   
  fabric-ca-client register --caname ca.company.certs.com --id.name companyadmin --id.secret companyadminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  mkdir -p ../crypto-config/peerOrganizations/company.certs.com/peers
  mkdir -p ../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the peer0 msp"
  echo
   
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.company.certs.com -M ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/msp --csr.hosts peer0.company.certs.com --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.company.certs.com -M ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls --enrollment.profile tls --csr.hosts peer0.company.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/company.certs.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/company.certs.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/tlsca/tlsca.company.certs.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/company.certs.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/peers/peer0.company.certs.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/ca/ca.company.certs.com-cert.pem

  # --------------------------------------------------------------------------------
 
  mkdir -p ../crypto-config/peerOrganizations/company.certs.com/users
  mkdir -p ../crypto-config/peerOrganizations/company.certs.com/users/User1@company.certs.com

  echo
  echo "## Generate the user msp"
  echo
   
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca.company.certs.com -M ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/User1@company.certs.com/msp --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/User1@company.certs.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/User1@company.certs.com/msp/keystore/priv_sk

  mkdir -p ../crypto-config/peerOrganizations/company.certs.com/users/Admin@company.certs.com

  echo
  echo "## Generate the org admin msp"
  echo
   
  fabric-ca-client enroll -u https://companyadmin:companyadminpw@localhost:8054 --caname ca.company.certs.com -M ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/Admin@company.certs.com/msp --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/Admin@company.certs.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/Admin@company.certs.com/msp/keystore/priv_sk

  cp ${PWD}/../crypto-config/peerOrganizations/company.certs.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/company.certs.com/users/Admin@company.certs.com/msp/config.yaml

}

# createCertificateForcompany

createCretificatesForOrderer() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/ordererOrganizations/certs.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/ordererOrganizations/certs.com

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/config.yaml

  echo
  echo "Register orderer"
  echo
   
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  echo
  echo "Register orderer2"
  echo
   
  fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  echo
  echo "Register orderer3"
  echo
   
  fabric-ca-client register --caname ca-orderer --id.name orderer3 --id.secret ordererpw --id.type orderer --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  echo
  echo "Register the orderer admin"
  echo
   
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  mkdir -p ../crypto-config/ordererOrganizations/certs.com/orderers
  # mkdir -p ../crypto-config/ordererOrganizations/certs.com/orderers/certs.com

  # ---------------------------------------------------------------------------
  #  Orderer

  mkdir -p ../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com

  echo
  echo "## Generate the orderer msp"
  echo
   
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/msp --csr.hosts orderer.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls --enrollment.profile tls --csr.hosts orderer.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

  mkdir ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

  # -----------------------------------------------------------------------
  #  Orderer 2

  mkdir -p ../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com

  echo
  echo "## Generate the orderer msp"
  echo
   
  fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/msp --csr.hosts orderer2.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls --enrollment.profile tls --csr.hosts orderer2.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

  # mkdir ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/tlscacerts
  # cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer2.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

  # ---------------------------------------------------------------------------
  #  Orderer 3
  mkdir -p ../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com

  echo
  echo "## Generate the orderer msp"
  echo
   
  fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/msp --csr.hosts orderer3.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls --enrollment.profile tls --csr.hosts orderer3.certs.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

  # mkdir ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/tlscacerts
  # cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/orderers/orderer3.certs.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/tlscacerts/tlsca.certs.com-cert.pem

  # ---------------------------------------------------------------------------

  mkdir -p ../crypto-config/ordererOrganizations/certs.com/users
  mkdir -p ../crypto-config/ordererOrganizations/certs.com/users/Admin@certs.com

  echo
  echo "## Generate the admin msp"
  echo
   
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/certs.com/users/Admin@certs.com/msp --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/certs.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/certs.com/users/Admin@certs.com/msp/config.yaml

}

# createCretificateForOrderer

removeOldCredentials() {
  sudo rm -rf ../../../../api-2.0/company-wallet/*
  sudo rm -rf ../../../../api-2.0/superadmin-wallet/*
  sudo rm -rf ../crypto-config/*
}

createConnectionProfile() {
  cd ../../../../api-2.0/config && ./generate-ccp.sh
}

removeOldCredentials
createcertificatesForsuperadmin
createCertificatesForcompany
createCretificatesForOrderer
createConnectionProfile