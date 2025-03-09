const express = require('express');
const {auth} = require('../../middlewares/auth');
const {  getHistoryById, getAssetId, createAsset } = require('../../controllers/asset.controller');

const router = express.Router();

router
  .route('/:id')
  .get(auth,  getAssetId); 

router
  .route('/history/:id')
  .get(auth, getHistoryById);

router
  .route('/')
  .post(auth, createAsset)

module.exports = router;