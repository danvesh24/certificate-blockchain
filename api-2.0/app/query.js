const { Gateway, Wallets, } = require('fabric-network');
const fs = require('fs');
const path = require("path")
const log4js = require('log4js');
const logger = log4js.getLogger('BasicNetwork');
const util = require('util')


const helper = require('./helper')
const query = async (channelName, chaincodeName, args, fcn, username, org_name) => {

    try {

        // load the network configuration
        // const ccpPath = path.resolve(__dirname, '..', 'config', 'connection-org1.json');
        // const ccpJSON = fs.readFileSync(ccpPath, 'utf8')
        const ccp = await helper.getCCP(org_name) //JSON.parse(ccpJSON);
        // const ccp = JSON.parse(ccpJSON);

        // Create a new file system based wallet for managing identities.
        const walletPath = await helper.getWalletPath(org_name) //.join(process.cwd(), 'wallet');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        let identity = await wallet.get(username);
        if (!identity) {
            console.log(`An identity for the user ${username} does not exist in the wallet, so registering user`);
            await helper.getRegisteredUser(username, org_name, true)
            identity = await wallet.get(username);
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, {
            wallet, identity: username, discovery: { enabled: true, asLocalhost: true }
        });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork(channelName);

        // Get the contract from the network.
        const contract = network.getContract(chaincodeName);
        let result;
        

        // * Company
        if (fcn == "QueryCompany") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        } else if(fcn == "QueryAllCompanies") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        } else if(fcn == "QueryCompaniesByIDs") {
            result = await contract.evaluateTransaction(fcn, ...args);
            console.log("---")
        
        } else if(fcn == "QueryCertificatesByIDs") {
            result = await contract.evaluateTransaction(fcn, ...args);
            console.log("---")
        }
        else if(fcn == "QueryCertificate") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        }
        
        // * Batch
        else if(fcn == "QueryBatch") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        }
        else if(fcn == "QueryAllBatches") {
            result = await contract.evaluateTransaction(fcn);
            console.log("---")
        } 
        else if(fcn == "QueryBatchesByIDs") {
            result = await contract.evaluateTransaction(fcn, ...args);
            console.log("---")
        } 
        // * Product
        else if(fcn == "QueryProductItem") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        } 
        else if(fcn == "QueryProduct") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        } 
        else if(fcn == "QueryProductsByIDs") {
            result = await contract.evaluateTransaction(fcn, ...args);
            console.log("---")
        } 
        // * Customer
         else if(fcn == "QueryCustomer") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---")
        }
        else if(fcn == "QueryCustomersByIDs") {
            result = await contract.evaluateTransaction(fcn, ...args);
            console.log("---")
        }
        else if (fcn == "readPrivateCar" || fcn == "queryPrivateDataHash"
        || fcn == "collectionCarPrivateDetails") {
            result = await contract.evaluateTransaction(fcn, args[0], args[1]);
            // return result

        }

        // Health Card 
        else if (fcn == "QueryHealthCard") {
            result = await contract.evaluateTransaction(fcn, args[0]);
            console.log("---");
        } else if (fcn == "QueryHealthCardsByIDs") {
            result = await contract.evaluateTransaction(fcn, ...args);
            console.log("---");
        } else if (fcn == "QueryAllHealthCards") {
            result = await contract.evaluateTransaction(fcn);
            console.log("---");
        } 
        console.log(result)
        console.log(`Transaction has been evaluated, result is: ${result.toString()}`);

        result = JSON.parse(result.toString());
        return result
    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        return error.message

    }
}

exports.query = query