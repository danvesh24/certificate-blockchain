const httpStatus = require('http-status');
const catchAsync = require('../utils/catchAsync');
const { getSuccessResponse } = require('../utils/Response');
const {  addAsset, queryAssetById, queryHistoryById } = require('../services/asset.service');

const createAsset = catchAsync(async (req, res) => {
  let { user } = req.loggerInfo;
  console.log('============user========', user);
  const result = await addAsset(req.body, user) 
  res.status(httpStatus.CREATED).send(getSuccessResponse(httpStatus.CREATED, 'Asset data created successfully', result));
});

const getHistoryById = catchAsync(async (req, res) => {
  const { id } = req.params;

  let { user } = req.loggerInfo;
  let data = await queryHistoryById(id, user);

  res.status(httpStatus.OK).send(getSuccessResponse(httpStatus.OK, 'Asset fetched successfully', data));
});

const getAssetId = catchAsync(async (req, res) => {
  const { id } = req.params;

  let { user } = req.loggerInfo;
  let data = await queryAssetById(id, user)

  res.status(httpStatus.OK).send(getSuccessResponse(httpStatus.OK, 'Asset fetched successfully', data));
});

module.exports = {
  createAsset,
  getAssetId,
  getHistoryById,
};