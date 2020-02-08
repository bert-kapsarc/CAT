var express = require('express');
var router = express.Router();

router.get('/', async function (req, res,) {
    res.render('index', { 
        carbon: await carboTag.callFn('totalCarbon'),
        gold: await carboTag.callFn('totalGold'),
        users: await carboTag.callFn('accountCount'),
        stampers: await carboTag.callFn('stamperCount')
        //contract: require('../public/javascripts/contract'),
    })

})
module.exports = router;


