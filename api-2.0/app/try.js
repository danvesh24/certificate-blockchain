const invokeTransaction = async (channelName, chaincodeName, fcn, args, userid, org_name) => {
    try {
        logger.debug(util.format('\n============ Invoke transaction on channel %s ============\n', channelName));

        // Load network configuration
        const ccp = await helper.getCCP(org_name);

        // Create wallet
        const walletPath = await helper.getWalletPath(org_name);
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        // Check if user exists
        let identity = await wallet.get(userid);
        if (!identity) {
            console.log(`User ${userid} not found. Registering user.`);
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

        const gateway = new Gateway();
        await gateway.connect(ccp, connectOptions);

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);
        const transaction = contract.createTransaction(fcn);

        let result = await contract.submitTransaction(fcn, ...args);
        let txId = transaction.getTransactionId(); // Initial proposal transaction ID

        // ✅ Fetch the ACTUAL transaction ID from the event listener
        const listener = async (event) => {
            if (event.payload) {
                const eventJson = JSON.parse(event.payload.toString());
                console.log(`✅ Transaction Event Received: ${JSON.stringify(eventJson)}`);
                txId = eventJson.tx_id; // Extract the actual transaction ID
            }
        };

        const eventService = network.getChannel().getEventService();
        eventService.registerTransactionListener(txId, listener);

        await gateway.disconnect();
        console.log("Gateway Stopped");

        let response = {
            success: true,
            message: `Transaction ${fcn} executed successfully.`,
            result: result.toString(),
            transactionId: txId // Now contains the final, committed transaction ID
        };

        return response;

    } catch (error) {
        console.error(`Error occurred: ${error.message}`);
        throw error;
    }
};
