var express = require('express');
var router = express.Router();
//require('../public/javascripts/transactions');

data = {}
data.escrows =[]
router.param('user_wallet', async function(req, res, next, _address){
    data.user = await carboTag.callFn('wallet',_address)
    console.log(data.user.escrowList)
    for (i = 0; i < data.user.escrowList.length; i++) {
        
        let escrow = new Contract(contract.escrowAbi,data.user.escrowList[i])
        let txCount = escrow.callFn('getTransactionIds')
        let pending = escrow.callFn('transactionCount',[0, txCount, true, false])
        let failed = escrow.callFn('transactionCount',[0, txCount, false, false])
        let owners = escrow.callFn('owners')
        owners.splice( owners.indexOf(contract.address), 1 );
        owners.splice( owners.indexOf(_address), 1 );
        
        let counterparties = []
        for (j = 0; i < owners.length; j++) {
            let user = carboTag.callFn('wallet',owners[j])
            counterparties.push({name: user.name, address: owners[j]})
        }
        data.escrows.push({
            address: data.user.escrowList[i], 
            pending: pending, 
            counterparties: counterparties
        })
    }
    next();
})

router.get('/:user_wallet', function (req, res) {
    res.render('index', {data: data})
})

module.exports = router;