
const { Gateway, Wallets, DefaultEventHandlerStrategies } = require('fabric-network');
const fs = require('fs');
const path = require("path");
const log4js = require('log4js');
const logger = log4js.getLogger('BasicNetwork');
const util = require('util');
const helper = require('./helper');

const invokeTransaction = async (channelName, chaincodeName, fcn, args, userid, org_name) => {
    try {
        logger.debug(util.format('\n============ invoke transaction on channel %s ============\n', channelName));

        // Load network configuration
        const ccp = await helper.getCCP(org_name);
        
        // Create wallet
        const walletPath = await helper.getWalletPath(org_name);
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check if the user is enrolled
        let identity = await wallet.get(userid);
        if (!identity) {
            console.log(`An identity for the user ${userid} does not exist in the wallet, so registering user`);
            await helper.getRegisteredUser(userid, org_name, true);
            identity = await wallet.get(userid);
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        const connectOptions = {
            wallet, 
            identity: userid, 
            discovery: { enabled: true, asLocalhost: true },
            eventHandlerOptions: {
                commitTimeout: 100,
                strategy: DefaultEventHandlerStrategies.NETWORK_SCOPE_ALLFORTX
            }
        };

        // Create a new gateway for connecting to the peer node
        const gateway = new Gateway();
        await gateway.connect(ccp, connectOptions);

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);
        // const transaction = contract.createTransaction(fcn);

        let result;
        let message;
        // let txId;
        
        // User
        if (fcn === "CreateCompany") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            // args[1] is the firstName; adjust as needed
            message = `Successfully added the user asset with name ${args[1]}`;
        } else if (fcn === "EditUser") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            // args[0] is the user ID
            message = `Successfully edited the user asset with ID ${args[0]}`;
        } else if (fcn === "GetUserWithHash") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `User Hashes`;
        }
        // Certificate 
        else if (fcn === "CreateCertificate") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully added the certificate asset with reference ${args[0]}`;
        } else if (fcn === "EditCertificate") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully edited the certificate asset with ID ${args[0]}`;
        } else if (fcn === "QueryCertificate") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Certificate details for ID ${args[0]}`;
        } else if (fcn === "QueryAllCertificates") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `All certificate assets retrieved`;
        } else if (fcn === "ChangeCertificateStatus") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Certificate status updated for ID ${args[0]}`;
        } else if (fcn === "GetCertificateWithHash") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Certificate hash details retrieved`;
        

        //Batch
        } else if (fcn === "CreateBatch") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully added the Batch with ID ${args[0]} and Batch Name ${args[1]}`;
        }
        else if (fcn === "EditBatch") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully edited the Batch with ID ${args[0]}`;
        }
        else if (fcn === "GetBatchWithHash") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Batch Hashes`;
        }

        //Product
        else if (fcn === "CreateProductItem") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully added the Product with ID ${args[0]} and Name ${args[1]}`;
        }
        else if (fcn === "EditProductItem") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully edited the Product with ID ${args[0]} and Name ${args[1]}`;
        }
        else if (fcn === "ChangeProductItemStatus") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Successfully changed the status of Product with ID ${args[0]}`;
        }
        else if (fcn === "GetProductWithHash") {
            result = await contract.submitTransaction(fcn, ...args);
            console.log('Stringified Result:', JSON.stringify(result));
            message = `Product Hashes`;
        }
         else {
            return `Invocation require either CreateCustomer, EditCustomer, GetCustomerWithHash, CreateCompany, ChangeCompanyStatus, GetCompanyWithHash, CreateBatch, EditBatch, GetBatchWithHash, CreateProductItem, EditProductItem or GetProductWithHash as function but got ${fcn}`
        }
        // Other similar function cases...

        await gateway.disconnect();
        console.log("Gateway Stopped");

        let response = {
            success: true,
            message: message,
            result
        }

        // Parse result to JSON if possible
        let parsedResult;
        try {
            parsedResult = JSON.parse(result.toString());
            response.result = parsedResult;
        } catch (error) {
            console.warn('Result is not valid JSON. Keeping raw output.');
            response.result = result.toString();
        }

        return response;

    } catch (error) {
        // Check if the error is related to the DiscoveryService failure
        if (error.message && error.message.includes('DiscoveryService has failed to return results')) {
            console.error('DiscoveryService failure: ' + error.message);
            throw new Error('DiscoveryService has failed to return results');
        }
        console.error(`Error occurred: ${error.message}`);
        throw error;  // Throw any other errors encountered
    }
};

exports.invokeTransaction = invokeTransaction;  