const { User } = require('../models');
const { getContractObject } = require('../utils/blockchainUtils');
const {
  NETWORK_ARTIFACTS_DEFAULT,
} = require('../utils/Constants');
const { getUUID } = require('../utils/uuid');
const Organization = require('../models/organization.model'); // Import your organization model


// If we are sure that max records are limited, we can use any max number
const utf8Decoder = new TextDecoder();


/**
 * Create a user
 * @param {Object} userBody
 * @returns {Promise<Agreement>}
 */
const addAsset = async (assetData, user) => {

  console.log("----------data--------------",assetData, user )
  let gateway;
  let client
  try {
    let dateTime = new Date();
    let orgId = user.orgId;

    let orgData = await Organization.findOne({ id: orgId });
  
    const data = {
      id:getUUID(),
     ...assetData,
      createAt: dateTime,
      updatedAt: dateTime,
    };

    console.log("orgName:", orgData.name);
    let orgName = orgData.name;

    const contract = await getContractObject(
      orgName,
      user.email,
      NETWORK_ARTIFACTS_DEFAULT.CHANNEL_NAME,
      NETWORK_ARTIFACTS_DEFAULT.CHAINCODE_NAME,
      gateway,
      client
    );

    await contract.submitTransaction("CreateCompany", JSON.stringify(data));

    return data;
  } catch (error) {
    console.log(error);
  } finally {
    if (gateway) {
      gateway.close();
    }
    if (client) {
      client.close()
    }
  }
};

const queryHistoryById = async (id, user) => {
  let gateway;
  let client
  try {
    let orgName = user.orgName;
    const contract = await getContractObject(
      orgName,
      user.email,
      NETWORK_ARTIFACTS_DEFAULT.CHANNEL_NAME,
      NETWORK_ARTIFACTS_DEFAULT.CHAINCODE_NAME,
      gateway,
      client
    );
    let result = await contract.submitTransaction('getAssetHistory', id);
    result = JSON.parse(utf8Decoder.decode(result));
    if (result) {
      result = result?.map(elm => {
        return { txId: elm?.txId, IsDelete: elm.IsDelete, ...elm.Value, timeStamp: elm?.Timestamp?.seconds?.low * 1000 }
      })
    }
    return result;
  } catch (error) {
    console.log(error);
  } finally {
    if (gateway) {
      gateway.close();
    }
    if (client) {
      client.close()
    }
  }
};

/**
 * Get user by id
 * @param {ObjectId} id
 * @returns {Promise<User>}
 */
const queryAssetById = async (id, user) => {
  let gateway;
  let client;
  try {
    let orgName = user.orgName;

    const contract = await getContractObject(
      orgName,
      user.email,
      NETWORK_ARTIFACTS_DEFAULT.CHANNEL_NAME,
      NETWORK_ARTIFACTS_DEFAULT.CHAINCODE_NAME,
      gateway,
      client
    );
    let result = await contract.submitTransaction('getAssetByID', id);
    console.timeEnd('Test');
    result = JSON.parse(utf8Decoder.decode(result));
   
    return result;
  } catch (error) {
    console.log(error);
  } finally {
    if (gateway) {
      gateway.close();
    }
    if (client) {
      client.close()
    }
  }
};

/**
 * Get user by email
 * @param {string} email
 * @returns {Promise<User>}
 */
const getUserByEmail = async (email) => {
  return User.findOne({ email });
};



module.exports = {
  addAsset,
  getUserByEmail,
  queryHistoryById,
  queryAssetById
};