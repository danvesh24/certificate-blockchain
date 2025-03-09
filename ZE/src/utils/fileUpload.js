const multer = require('multer');
const fs = require('fs');
const path = require('path');
require('dotenv').config();
const httpStatus = require('http-status');
const { getSuccessResponse } = require('./Response');
const logger = require('../logger')(module);
const validate = require('../middlewares/validate');
const agreementValidation = require('../validations/agreement.validation');

const fileSizeLimit = 5242880; // 5MB Max File size allowed

// Set up Multer storage configuration for local file storage
const upload = multer({
  storage: multer.diskStorage({
    destination: function (_req, _file, cb) {
      const uploadPath = path.resolve(__dirname, '../../', 'uploads');
      if (!fs.existsSync(uploadPath)) {
        fs.mkdirSync(uploadPath, { recursive: true });
      }
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      cb(null, `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
    },
  }),
  limits: { fileSize: fileSizeLimit },
  fileFilter: (req, file, cb) => {
    logger.info({ userInfo: req.loggerInfo, method: 'Upload', fileMimeType: file.mimetype });
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      return cb(new Error('Only .pdf format allowed!'));
    }
  },
});

const imageUpload = upload.fields([{ name: 'agreement', maxCount: 1 }]);

exports.uploadFileLocally = async (req, res, next) => {
  logger.info({ userInfo: req.loggerInfo, method: 'uploadFileLocally' });
  imageUpload(req, res, async (err) => {
    try {
      const { value: data, error } = agreementValidation.createAgreement.prefs({ errors: { label: 'key' }, abortEarly: false }).validate(req.body);
      if (error) {
        const errorMessage = error.details.map((details) => details.message).join(', ');
        return res.status(httpStatus.BAD_REQUEST).send(getSuccessResponse(httpStatus.BAD_REQUEST, errorMessage));
      }
      if (err) {
        logger.error({ userInfo: req.loggerInfo, method: 'uploadFileLocally', error: 'Error in imageUpload : ' + err });
        if (err.message == 'Unexpected field') {
          err.message = 'Invalid number of files / Invalid key in form data';
        }
        return res.status(httpStatus.FORBIDDEN).send(getSuccessResponse(httpStatus.FORBIDDEN, err.message));
      }
      if (req.body.isUpdate && !req.files?.length) {
        next();
      } else {
        const files = req.files;
        if (!files?.agreement?.length) {
          logger.error({ userInfo: req.loggerInfo, method: 'uploadFileLocally', error: 'No files selected' });
          return res.status(httpStatus.FORBIDDEN).send(getSuccessResponse(httpStatus.FORBIDDEN, 'No files selected'));
        }
        if (req.files.agreement) {
          let fileMetadata = await saveFileLocally(req.files.agreement[0]);
          logger.info({ userInfo: req.loggerInfo, method: 'uploadFileLocally', info: fileMetadata });
          req.body.fileMetadata = fileMetadata;
        }
        next();
      }
    } catch (error) {
      logger.error({ userInfo: req.loggerInfo, method: 'uploadFileLocally', error: error });
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).send(getSuccessResponse(httpStatus.INTERNAL_SERVER_ERROR, error.message));
    }
  });
};

const saveFileLocally = async (file) => {
  const fileData = fs.readFileSync(file.path);
  const fileHash = getDataHash(fileData);
  const fileName = `${fileHash}-${file.originalname}`;
  const destinationPath = path.resolve(__dirname, '../../uploads', fileName);

  // Move the file to the final destination path
  fs.renameSync(file.path, destinationPath);

  return {
    id: fileName,
    name: file.originalname.replace(/\.[^/.]+$/, ''),
    path: destinationPath,
    contentHash: fileHash,
  };
};

const getDataHash = (data) => {
  const crypto = require('crypto');
  const hash = crypto.createHash('sha1');
  hash.update(data);
  return hash.digest('hex');
};

module.exports.imageUpload = imageUpload;
module.exports.saveFileLocally = saveFileLocally;
