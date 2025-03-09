createcertificatesForsuperadmin() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/peerOrganizations/superadmin.productauth.com/
  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca.superadmin.productauth.com --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem
   

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-productauth-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-productauth-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-productauth-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-superadmin-productauth-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/msp/config.yaml

  echo
  echo "Register peer0"
  echo
  fabric-ca-client register --caname ca.superadmin.productauth.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  echo
  echo "Register user"
  echo
  fabric-ca-client register --caname ca.superadmin.productauth.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  echo
  echo "Register the org admin"
  echo
  fabric-ca-client register --caname ca.superadmin.productauth.com --id.name superadminadmin --id.secret superadminadminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  mkdir -p ../crypto-config/peerOrganizations/superadmin.productauth.com/peers

  # -----------------------------------------------------------------------------------
  #  Peer 0
  mkdir -p ../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com

  echo
  echo "## Generate the peer0 msp"
  echo
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca.superadmin.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/msp --csr.hosts peer0.superadmin.productauth.com --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca.superadmin.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls --enrollment.profile tls --csr.hosts peer0.superadmin.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem

  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/tlsca/tlsca.superadmin.productauth.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/peers/peer0.superadmin.productauth.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/ca/ca.superadmin.productauth.com-cert.pem

  # --------------------------------------------------------------------------------------------------

  mkdir -p ../crypto-config/peerOrganizations/superadmin.productauth.com/users
  mkdir -p ../crypto-config/peerOrganizations/superadmin.productauth.com/users/User1@superadmin.productauth.com

  echo
  echo "## Generate the user msp"
  echo
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca.superadmin.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/User1@superadmin.productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/User1@superadmin.productauth.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/User1@superadmin.productauth.com/msp/keystore/priv_sk
  mkdir -p ../crypto-config/peerOrganizations/superadmin.productauth.com/users/Admin@superadmin.productauth.com

  echo
  echo "## Generate the org admin msp"
  echo
  fabric-ca-client enroll -u https://superadminadmin:superadminadminpw@localhost:7054 --caname ca.superadmin.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/Admin@superadmin.productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/superadmin/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/Admin@superadmin.productauth.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/Admin@superadmin.productauth.com/msp/keystore/priv_sk
  cp ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/superadmin.productauth.com/users/Admin@superadmin.productauth.com/msp/config.yaml

}

# createcertificatesForsuperadmin

createCertificatesForcompany() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p /../crypto-config/peerOrganizations/company.productauth.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/company.productauth.com/

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca.company.productauth.com --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-productauth-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-productauth-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-productauth-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-company-productauth-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/company.productauth.com/msp/config.yaml

  echo
  echo "Register peer0"
  echo
   
  fabric-ca-client register --caname ca.company.productauth.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  echo
  echo "Register user"
  echo
   
  fabric-ca-client register --caname ca.company.productauth.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  echo
  echo "Register the org admin"
  echo
   
  fabric-ca-client register --caname ca.company.productauth.com --id.name companyadmin --id.secret companyadminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  mkdir -p ../crypto-config/peerOrganizations/company.productauth.com/peers
  mkdir -p ../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the peer0 msp"
  echo
   
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.company.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/msp --csr.hosts peer0.company.productauth.com --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca.company.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls --enrollment.profile tls --csr.hosts peer0.company.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
   

  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/tlsca/tlsca.company.productauth.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/peers/peer0.company.productauth.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/ca/ca.company.productauth.com-cert.pem

  # --------------------------------------------------------------------------------
 
  mkdir -p ../crypto-config/peerOrganizations/company.productauth.com/users
  mkdir -p ../crypto-config/peerOrganizations/company.productauth.com/users/User1@company.productauth.com

  echo
  echo "## Generate the user msp"
  echo
   
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca.company.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/User1@company.productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/User1@company.productauth.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/User1@company.productauth.com/msp/keystore/priv_sk

  mkdir -p ../crypto-config/peerOrganizations/company.productauth.com/users/Admin@company.productauth.com

  echo
  echo "## Generate the org admin msp"
  echo
   
  fabric-ca-client enroll -u https://companyadmin:companyadminpw@localhost:8054 --caname ca.company.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/Admin@company.productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/company/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/Admin@company.productauth.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/Admin@company.productauth.com/msp/keystore/priv_sk

  cp ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/company.productauth.com/users/Admin@company.productauth.com/msp/config.yaml

}

# createCertificateForcompany

createCertificatesForretailer() {
  echo
  echo "Enroll the CA admin"
  echo 
  mkdir -p ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/


  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/

   
  fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 --caname ca.retailer.productauth.com --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
   
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-retailer-productauth-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-retailer-productauth-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-retailer-productauth-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-retailer-productauth-com.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/msp/config.yaml

  echo
  echo "Register peer0"
  echo
   
  fabric-ca-client register --caname ca.retailer.productauth.com --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
   

  echo
  echo "Register user"
  echo
   
  fabric-ca-client register --caname ca.retailer.productauth.com --id.name user1 --id.secret user1pw --id.type client --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
   

  echo
  echo "Register the org admin"
  echo
   
  fabric-ca-client register --caname ca.retailer.productauth.com --id.name retaileradmin --id.secret retaileradminpw --id.type admin --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
   

  mkdir -p ../crypto-config/peerOrganizations/retailer.productauth.com/peers
  mkdir -p ../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com

  # --------------------------------------------------------------
  # Peer 0
  echo
  echo "## Generate the peer0 msp"
  echo
   
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca.retailer.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/msp --csr.hosts peer0.retailer.productauth.com --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
   

  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca.retailer.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls --enrollment.profile tls --csr.hosts peer0.retailer.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
   

  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/ca.crt
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/signcerts/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/server.crt
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/keystore/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/server.key

  mkdir ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/msp/tlscacerts/ca.crt

  mkdir ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/tlsca
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/tlsca/tlsca.retailer.productauth.com-cert.pem

  mkdir ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/ca
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/peers/peer0.retailer.productauth.com/msp/cacerts/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/ca/ca.retailer.productauth.com-cert.pem

  # --------------------------------------------------------------------------------
 
  mkdir -p ../crypto-config/peerOrganizations/retailer.productauth.com/users
  mkdir -p ../crypto-config/peerOrganizations/retailer.productauth.com/users/User1@retailer.productauth.com

  echo
  echo "## Generate the user msp"
  echo
   
  fabric-ca-client enroll -u https://user1:user1pw@localhost:10054 --caname ca.retailer.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/User1@retailer.productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/User1@retailer.productauth.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/User1@retailer.productauth.com/msp/keystore/priv_sk

  mkdir -p ../crypto-config/peerOrganizations/retailer.productauth.com/users/Admin@retailer.productauth.com

  echo
  echo "## Generate the org admin msp"
  echo
   
  fabric-ca-client enroll -u https://retaileradmin:retaileradminpw@localhost:10054 --caname ca.retailer.productauth.com -M ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/Admin@retailer.productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/retailer/tls-cert.pem
  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/Admin@retailer.productauth.com/msp/keystore/* ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/Admin@retailer.productauth.com/msp/keystore/priv_sk

  cp ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/msp/config.yaml ${PWD}/../crypto-config/peerOrganizations/retailer.productauth.com/users/Admin@retailer.productauth.com/msp/config.yaml

}

# createCertificateForretailer


createCretificatesForOrderer() {
  echo
  echo "Enroll the CA admin"
  echo
  mkdir -p ../crypto-config/ordererOrganizations/productauth.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/../crypto-config/ordererOrganizations/productauth.com

   
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
    OrganizationalUnitIdentifier: orderer' >${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/config.yaml

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
   

  mkdir -p ../crypto-config/ordererOrganizations/productauth.com/orderers
  # mkdir -p ../crypto-config/ordererOrganizations/productauth.com/orderers/productauth.com

  # ---------------------------------------------------------------------------
  #  Orderer

  mkdir -p ../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com

  echo
  echo "## Generate the orderer msp"
  echo
   
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/msp --csr.hosts orderer.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls --enrollment.profile tls --csr.hosts orderer.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/msp/tlscacerts/tlsca.productauth.com-cert.pem

  mkdir ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/tlscacerts/tlsca.productauth.com-cert.pem

  # -----------------------------------------------------------------------
  #  Orderer 2

  mkdir -p ../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com

  echo
  echo "## Generate the orderer msp"
  echo
   
  fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/msp --csr.hosts orderer2.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://orderer2:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls --enrollment.profile tls --csr.hosts orderer2.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/msp/tlscacerts/tlsca.productauth.com-cert.pem

  # mkdir ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/tlscacerts
  # cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer2.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/tlscacerts/tlsca.productauth.com-cert.pem

  # ---------------------------------------------------------------------------
  #  Orderer 3
  mkdir -p ../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com

  echo
  echo "## Generate the orderer msp"
  echo
   
  fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/msp --csr.hosts orderer3.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
   
  fabric-ca-client enroll -u https://orderer3:ordererpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls --enrollment.profile tls --csr.hosts orderer3.productauth.com --csr.hosts localhost --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/ca.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/signcerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/server.crt
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/keystore/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/server.key

  mkdir ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/msp/tlscacerts
  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/msp/tlscacerts/tlsca.productauth.com-cert.pem

  # mkdir ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/tlscacerts
  # cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/orderers/orderer3.productauth.com/tls/tlscacerts/* ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/tlscacerts/tlsca.productauth.com-cert.pem

  # ---------------------------------------------------------------------------

  mkdir -p ../crypto-config/ordererOrganizations/productauth.com/users
  mkdir -p ../crypto-config/ordererOrganizations/productauth.com/users/Admin@productauth.com

  echo
  echo "## Generate the admin msp"
  echo
   
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M ${PWD}/../crypto-config/ordererOrganizations/productauth.com/users/Admin@productauth.com/msp --tls.certfiles ${PWD}/fabric-ca/ordererOrg/tls-cert.pem
   

  cp ${PWD}/../crypto-config/ordererOrganizations/productauth.com/msp/config.yaml ${PWD}/../crypto-config/ordererOrganizations/productauth.com/users/Admin@productauth.com/msp/config.yaml

}

# createCretificateForOrderer

removeOldCredentials() {
  sudo rm -rf ../../../../api-2.0/company-wallet/*
  sudo rm -rf ../../../../api-2.0/superadmin-wallet/*
  sudo rm -rf ../../../../api-2.0/retailer-wallet/*
  sudo rm -rf ../crypto-config/*
}

createConnectionProfile() {
  cd ../../../../api-2.0/config && ./generate-ccp.sh
}

removeOldCredentials
createcertificatesForsuperadmin
createCertificatesForcompany
createCertificatesForretailer

createCretificatesForOrderer

createConnectionProfile