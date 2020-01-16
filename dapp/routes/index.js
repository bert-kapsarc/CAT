var express = require('express');
var router = express.Router();

router.get('/', async function (req, res,) {
    res.render('index', { 
        title: 'CarboTag',
        tags: await carboTag.callFn('totalTag'),
        gold: await carboTag.callFn('totalGold'),
        users: await carboTag.callFn('accountCount'),
        stampers: await carboTag.callFn('stamperCount'),
        //contract: require('../public/javascripts/contract'),
        abi: JSON.stringify(abi),
        address: process.env.CARBO_TAG_ADDR,
        rpcURL: process.env.INFURA_ROPSTEN
    })

})
module.exports = router;


