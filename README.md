
# Hyperledger Fabric Network

This repository contains the setup and configuration for a Hyperledger Fabric network. Follow the instructions below to get started with setting up the network on your local machine.

---

## Prerequisites

Before setting up the network, ensure you have the following installed:

### 1. Go Programming Language
Install the latest version of Go from the official [Go website](https://golang.org/dl/).
- Recommended: go version go1.18.1

### 2. Fabric Samples, Binaries, and Docker Images
Download the `fabric-samples` repository using the following commands:
```bash
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
```

### 3. Set PATH for Binaries
Add the Fabric binaries to your system's PATH:

- For Ubuntu/Linux
Add the following line to your ~/.bashrc file:

``` bash
export PATH=$PATH:/home/<your-username>/go/src/github.com/fabric-samples/bin
```

Then reload bash configuration 

``` bash
source ~/.bashrc
```

- For macOS
Add the following line to your ~/.zshrc or ~/.bash_profile file:

``` bash
export PATH=$PATH:/Users/<your-username>/go/src/github.com/fabric-samples/bin
```

Then, reload the shell configuration:

``` bash
source ~/.zshrc  # or source ~/.bash_profile
```

## Setting Up the Blockchain Network

### 1. Cleanup Before Starting the Network
Before running the network, remove the following directories:

- Fabric CA Data:
Delete the fabric-ca folder inside blockchain/artifacts/channel/create-certificate-with-ca/:

``` bash
rm -rf blockchain/artifacts/channel/create-certificate-with-ca/fabric-ca

```

- Crypto Material:

Delete the crypto-config folder:

``` bash
rm -rf blockchain/artifacts/channel/crypto-config
```

### 2. Navigate to the blockchain/scripts directory within the project folder:

``` bash
cd blockchain/scripts
```

### 2. Run the network.sh script to set up the blockchain network:

``` bash
./network.sh up
```
This script will start the Hyperledger Fabric network, including the necessary containers and configurations.

## How ./network.sh Works
The ./network.sh script automates the steps to set up the Hyperledger Fabric network. Here's a breakdown of its operations:

### 1. Start the Fabric CA
Navigate to the CA directory, then start the Fabric CA containers:

``` bash
cd ../artifacts/channel/create-certificate-with-ca/
docker-compose up -d
```

### 2. Generate Certificates
Run the create-certificate-with-ca.sh script to generate certificates:

``` bash
./create-certificate-with-ca.sh
```

### 3. Generate Network Artifacts
Run the create-artifacts.sh script to generate channel configuration and artifacts:

```bash
cd .. && ./create-artifacts.sh
sleep 5
```

### 4. Start Docker Containers
Start the Docker containers for the network:

``` bash
cd ../
docker-compose up -d
```

### 5. Create the Channel
Navigate to the scripts folder and create the channel:

```bash
cd ../scripts
./createChannel.sh
```

### 6. Deploy the Chaincode
Deploy the chaincode to the network:

```bash
./deployChaincode_2.sh
```

## Additional Notes

- Ensure Docker and Docker Compose are installed and running on your system.
- Modify the network.sh script as needed for custom configurations.

## Troubleshooting

If you encounter issues while setting up the network, consider the following steps:

- Verify that all prerequisites are installed correctly.
- Check the logs for errors using the docker logs command for specific containers.
- Refer to the Hyperledger Fabric documentation for additional support.

=======
# certificate-blockchain

