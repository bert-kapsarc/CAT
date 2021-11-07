var express = require('express');
var router = express.Router();

router.get('/', async function (req, res,) {
    res.render('index', { 
        carbon: await cat.callFn('totalCarbon'),
        gold: await cat.callFn('totalGold'),
        users: await cat.callFn('userCount'),
        stampers: await cat.callFn('stamperCount')
        //contract: require('../public/javascripts/contract'),
    })

})
module.exports = router;


