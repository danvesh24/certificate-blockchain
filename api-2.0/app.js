'use strict';
var log4js = require('log4js');
var logger = log4js.getLogger('SampleWebApp');
var express = require('express');
var bodyParser = require('body-parser');
var http = require('http');
var util = require('util');
var app = express();
var expressJWT = require('express-jwt');
var jwt = require('jsonwebtoken');
var bearerToken = require('express-bearer-token');
var cors = require('cors');
const constants = require('./config/constants.json')

const host = process.env.HOST || '0.0.0.0';
// const host = "192.168.1.97"
const port = process.env.PORT || constants.port;

var helper = require('./app/helper')
var invoke = require('./app/invoke')
var qscc = require('./app/qscc')
var query = require('./app/query')

app.options('*', cors());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
    extended: false
}));
// set secret variable
app.set('secret', 'thisismysecret');
app.use(expressJWT({
    secret: 'thisismysecret'
}).unless({
    path: ['/users','/users/login', '/register', '/users/token', '/users/revoke', '/users/identity']
}));
app.use(bearerToken());

logger.level = 'debug';

app.use((req, res, next) => {
    logger.debug('New req for %s', req.originalUrl);
    if (req.originalUrl.indexOf('/users') >= 0 || req.originalUrl.indexOf('/users/login') >= 0 || req.originalUrl.indexOf('/register') >= 0) {
        return next();
    }
    var token = req.token;
    jwt.verify(token, app.get('secret'), (err, decoded) => {
        if (err) {
            console.log(`Error ================:${err}`)
            res.send({
                success: false,
                message: 'Failed to authenticate token. Make sure to include the ' +
                    'token returned from /users call in the authorization header ' +
                    ' as a Bearer token'
            });
            return;
        } else {
            req.userid = decoded.userid;
            req.orgname = decoded.orgName;
            req.companyname = decoded.companyName
            logger.debug(util.format('Decoded from JWT token: userid - %s, orgname - %s, companyname - %s', decoded.userid, decoded.orgName, decoded.companyName));
            return next();
        }
    });
});

var server = http.createServer(app).listen(port, function () { console.log(`Server started on ${port}`) });
logger.info('****************** SERVER STARTED ************************');
logger.info('***************  http://%s:%s  ******************', host, port);
server.timeout = 240000;

function getErrorMessage(field) {
    var response = {
        success: false,
        message: field + ' field is missing or Invalid in the request'
    };
    return response;
}

// Register and enroll user
app.post('/users', async function (req, res) {
    var userid = req.body.userid;
    var orgName = req.body.orgName;
    var companyName =  req.body.companyName
    logger.debug('End point : /users');
    logger.debug('User name : ' + userid);
    logger.debug('Org name  : ' + orgName);
    logger.debug('Company name  : ' + companyName);

    if (!userid) {
        res.json(getErrorMessage('\'userid\''));
        return;
    }
    if (!orgName) {
        res.json(getErrorMessage('\'orgName\''));
        return;
    }
    if (!companyName) {
        res.json(getErrorMessage('\'companyName\''));
        return;
    }

    var token = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + parseInt(constants.jwt_expiretime),
        userid: userid,
        orgName: orgName,
        companyName: companyName
    }, app.get('secret'));

    let response = await helper.getRegisteredUser(userid, orgName, companyName, true);

    logger.debug('-- returned from registering the userid %s for organization %s and company %s', userid, orgName, companyName);
    if (response && typeof response !== 'string') {
        logger.debug('Successfully registered the userid %s for organization %s and company %s', userid, orgName, companyName);
        response.token = token;
        res.json(response);
    } else {
        logger.debug('Failed to register the userid %s for organization %s and company %s with::%s', userid, orgName, companyName, response);
        res.json({ success: false, message: response });
    }

});

// Register and enroll user
app.post('/register', async function (req, res) {
    var userid = req.body.userid;
    var orgName = req.body.orgName;
    var companyName =  req.body.companyName
    logger.debug('End point : /users');
    logger.debug('User name : ' + userid);
    logger.debug('Org name  : ' + orgName);
    logger.debug('Company name  : ' + companyName);
    if (!userid) {
        res.json(getErrorMessage('\'userid\''));
        return;
    }
    if (!orgName) {
        res.json(getErrorMessage('\'orgName\''));
        return;
    }
    if (!companyName) {
        res.json(getErrorMessage('\'companyName\''));
        return;
    }

    var token = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + parseInt(constants.jwt_expiretime),
        userid: userid,
        orgName: orgName,
        companyName: companyName
    }, app.get('secret'));

    console.log(token)

    let response = await helper.registerAndGerSecret(userid, orgName, companyName);

    logger.debug('-- returned from registering the userid %s for organization %s and company %s', userid, orgName, companyName);
    if (response && typeof response !== 'string') {
        logger.debug('Successfully registered the userid %s for organization %s and company %s', userid, orgName, companyName);
        response.token = token;
        res.json(response);
    } else {
        logger.debug('Failed to register the userid %s for organization %s and company %s with::%s', userid, orgName, companyName, response);
        res.json({ success: false, message: response });
    }

}); 

// Login and get jwt
app.post('/users/login', async function (req, res) {
    var userid = req.body.userid;
    var orgName = req.body.orgName;
    var companyName = req.body.companyName;
    logger.debug('End point : /users');
    logger.debug('User name : ' + userid);
    logger.debug('Org name  : ' + orgName);
    logger.debug('Company name  : ' + companyName);
    if (!userid) {
        res.json(getErrorMessage('\'userid\''));
        return;
    }
    if (!orgName) {
        res.json(getErrorMessage('\'orgName\''));
        return;
    }
    if (!companyName) {
        res.json(getErrorMessage('\'companyName\''));
        return;
    }

    var token = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + parseInt(constants.jwt_expiretime),
        userid: userid,
        orgName: orgName,
        companyName: companyName
    }, app.get('secret'));

    let isUserRegistered = await helper.isUserRegistered(userid, orgName, companyName);

    if (isUserRegistered) {
        res.json({ success: true, message: { token: token } });

    } else {
        res.json({ success: false, message: `User with userid ${userid} is not registered with ${orgName}, Please register first.` });
    }
});

app.post('/users/token', async function (req, res) {
    var userid = req.body.userid;
    var orgName = req.body.orgName;
    var companyName = req.body.companyName;
    logger.debug('End point : /users');
    logger.debug('User name : ' + userid);
    logger.debug('Org name  : ' + orgName);
    logger.debug('C name  : ' + companyName);
    if (!userid) {
        res.json(getErrorMessage('\'userid\''));
        return;
    }
    if (!orgName) {
        res.json(getErrorMessage('\'orgName\''));
        return;
    }
    if (!companyName) {
        res.json(getErrorMessage('\'companyName\''));
        return;
    }

    var token = jwt.sign({
        exp: Math.floor(Date.now() / 1000) + parseInt(constants.jwt_expiretime),
        userid: userid,
        orgName: orgName,
        companyName: companyName
    }, app.get('secret'));

    let isUserRegistered = await helper.isUserRegistered(userid, orgName, companyName);

    if (isUserRegistered) {
        res.json({ success: true, message: { token: token } });

    } else {
        res.json({ success: false, message: `User with userid ${userid} is not registered with ${orgName}, Please register first.` });
    }
});


// Invoke transaction on chaincode on target peers
app.post('/channels/:channelName/chaincodes/:chaincodeName', async function (req, res) {
    try {
        logger.debug('==================== INVOKE ON CHAINCODE ==================');
        var peers = req.body.peers;
        var chaincodeName = req.params.chaincodeName;
        var channelName = req.params.channelName;
        var fcn = req.body.fcn;
        var args = req.body.args;
        // var transient = req.body.transient;
        // console.log(`Transient data is ;${transient}`)
        logger.debug('channelName  : ' + channelName);
        logger.debug('chaincodeName : ' + chaincodeName);
        logger.debug('fcn  : ' + fcn);
        logger.debug('args  : ' + args);

        const functionMappings = {
            'CreateCompany': { channelName: 'mychannel', chaincodeName: 'Company' },
            'EditCompany': { channelName: 'mychannel', chaincodeName: 'Company' },
            'GetCompanyHash': { channelName: 'mychannel', chaincodeName: 'Company' },
            'CreateCustomer': { channelName: 'mychannel', chaincodeName: 'Customer'},
            'EditCustomer': { channelName: 'mychannel', chaincodeName: 'Customer'},
            'GetCustomerWithHash': { channelName: 'mychannel', chaincodeName: 'Customer'},
            'CreateBatch': { channelName: 'mychannel', chaincodeName: 'Batch'},
            'GetBatchWithHash': { channelName: 'mychannel', chaincodeName: 'Batch'},
            'EditBatch': { channelName: 'mychannel', chaincodeName: 'Batch'}, 
            'CreateProductItem': { channelName: 'mychannel', chaincodeName: 'Productitem'},
            'EditProductItem': { channelName: 'mychannel', chaincodeName: 'Productitem'},
            'GetProductWithHash': { channelName: 'mychannel', chaincodeName: 'Productitem'},
        };

        if (functionMappings[fcn]) {
            channelName = functionMappings[fcn].channelName;
            chaincodeName = functionMappings[fcn].chaincodeName;
        }

        console.log(`Mapped channel name is: ${channelName}`);
        console.log(`Mapped chaincode name is: ${chaincodeName}`);

        logger.debug('Mapped channelName: ' + channelName);
        logger.debug('Mapped chaincodeName: ' + chaincodeName);


        if (!chaincodeName) {
            res.json(getErrorMessage('\'chaincodeName\''));
            return;
        }
        if (!channelName) {
            res.json(getErrorMessage('\'channelName\''));
            return;
        }
        if (!fcn) {
            res.json(getErrorMessage('\'fcn\''));
            return;
        }
        if (!args) {
            res.json(getErrorMessage('\'args\''));
            return;
        }

        let message = await invoke.invokeTransaction(channelName, chaincodeName, fcn, args, req.userid, req.orgname, req.companyName);
        console.log(`message result is : ${message}`)

        const response_payload = {
            result: message,
            error: null,
            errorData: null
        }
        res.send(response_payload);

    } catch (error) {
        const response_payload = {
            result: null,
            error: error.name,
            errorData: error.message
        }
        res.send(response_payload)
    }
});

app.get('/channels/:channelName/chaincodes/:chaincodeName', async function (req, res) {
    try {
        logger.debug('==================== QUERY BY CHAINCODE ==================');

        var channelName = req.params.channelName;
        var chaincodeName = req.params.chaincodeName;
        console.log(`chaincode name is :${chaincodeName}`)
        let args = req.query.args;
        let fcn = req.query.fcn;
        let peer = req.query.peer;

        logger.debug('channelName : ' + channelName);
        logger.debug('chaincodeName : ' + chaincodeName);
        logger.debug('fcn : ' + fcn);
        logger.debug('args : ' + args);

        const functionMappings = {
            'CreateCompany': { channelName: 'mychannel', chaincodeName: 'Company' },
            'GetCompanyHash': { channelName: 'mychannel', chaincodeName: 'Company' },
            'QueryBatch': { channelName: 'mychannel', chaincodeName: 'Batch' },
            'QueryAllBatches': { channelName: 'mychannel', chaincodeName: 'Batch' },
            'QueryProductItem': { channelName: 'mychannel', chaincodeName: 'Productitem' },
            'QueryCustomer': { channelName: 'mychannel', chaincodeName: 'Customer' },
        };

        if (functionMappings[fcn]) {
            channelName = functionMappings[fcn].channelName;
            chaincodeName = functionMappings[fcn].chaincodeName;
        }

        console.log(`Mapped channel name is: ${channelName}`);
        console.log(`Mapped chaincode name is: ${chaincodeName}`);

        logger.debug('Mapped channelName: ' + channelName);
        logger.debug('Mapped chaincodeName: ' + chaincodeName);

        if (!chaincodeName) {
            res.json(getErrorMessage('\'chaincodeName\''));
            return;
        }
        if (!channelName) {
            res.json(getErrorMessage('\'channelName\''));
            return;
        }
        if (!fcn) {
            res.json(getErrorMessage('\'fcn\''));
            return;
        }
        if (!args) {
            res.json(getErrorMessage('\'args\''));
            return;
        }
        console.log('args==========', args);
        args = args.replace(/'/g, '"');
        args = JSON.parse(args);
        logger.debug(args);

        let message = await query.query(channelName, chaincodeName, args, fcn, req.userid, req.orgname, req.companyName);

        const response_payload = {
            result: message,
            error: null,
            errorData: null
        }

        res.send(response_payload);
    } catch (error) {
        const response_payload = {
            result: null,
            error: error.name,
            errorData: error.message
        }
        res.send(response_payload)
    }
});

app.get('/qscc/channels/:channelName/chaincodes/:chaincodeName', async function (req, res) {
    try {
        logger.debug('==================== QUERY BY CHAINCODE ==================');

        var channelName = req.params.channelName;
        var chaincodeName = req.params.chaincodeName;
        console.log(`chaincode name is :${chaincodeName}`)
        let args = req.query.args;
        let fcn = req.query.fcn;
        // let peer = req.query.peer;

        logger.debug('channelName : ' + channelName);
        logger.debug('chaincodeName : ' + chaincodeName);
        logger.debug('fcn : ' + fcn);
        logger.debug('args : ' + args);

        if (!chaincodeName) {
            res.json(getErrorMessage('\'chaincodeName\''));
            return;
        }
        if (!channelName) {
            res.json(getErrorMessage('\'channelName\''));
            return;
        }
        if (!fcn) {
            res.json(getErrorMessage('\'fcn\''));
            return;
        }
        if (!args) {
            res.json(getErrorMessage('\'args\''));
            return;
        }
        console.log('args==========', args);
        args = args.replace(/'/g, '"');
        args = JSON.parse(args);
        logger.debug(args);

        let response_payload = await qscc.qscc(channelName, chaincodeName, args, fcn, req.userid, req.orgname, req.companyName);

        // const response_payload = {
        //     result: message,
        //     error: null,
        //     errorData: null
        // }

        res.send(response_payload);
    } catch (error) {
        const response_payload = {
            result: null,
            error: error.name,
            errorData: error.message
        }
        res.send(response_payload)
    }
});

// TODO: Need to access the db and delete the identity
app.post('/users/revoke', async (req, res) => {
    const { userid, orgName, companyName } = req.body;

    if (!userid || !orgName) {
        return res.status(400).json({ success: false, message: 'Missing required fields: userid, userOrg' });
    }

    try {
        const response = await helper.revokeIdentity(userid, orgName);
        res.status(200).json(response);
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});



