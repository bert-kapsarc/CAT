var express = require('express');
var router = express.Router();

router.get('/',async function (req, res) {
    res.render('deploy')
})
.post('/',async function (req, res){
    res.render('deploy')
})

module.exports = router;