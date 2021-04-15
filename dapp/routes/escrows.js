var express = require('express');
var router = express.Router();
//require('../public/javascripts/transactions');
// for querying postgres
const { pool } = require('../config')

// Contract module to get instance of and call on MultiSigWallet
const Contract = require('../public/javascripts/contract');

const data = {}

router.param('user_wallet', async function(req, res, next, _address){
    data.escrows =[]
    var txIDs;
    let escrowList= await carboTag.callFn('getEscrowList',_address)
    for (i = 0; i < escrowList.length; i++) {
        let escrow = new Contract(contracts.escrowAbi,escrowList[i])
        let txCount = await escrow.callFn('transactionCount')
        if(txCount>0){
            txIDs = await escrow.callFn('getTransactionIds',[0, txCount, true, false])
        } 
        let pending = await escrow.callFn('getTransactionCount',[true,false])
        let failed = await escrow.callFn('getTransactionCount',[false, false])
        let owners = await escrow.callFn('getOwners')
        owners = owners.map(function(x){ return x.toLowerCase() })
        await owners.splice(owners.indexOf(contracts.carboTagAddr), 1 )
        await owners.splice(owners.indexOf(_address), 1 )
        let counterparties = []
        for (j = 0; j < owners.length; j++) {
            let user = await carboTag.callFn('wallet',owners[j])
            //console.log(user)
            counterparties.push({name: user.name, address: owners[j]})
        }

 
        data.escrows.push({
            address: escrowList[i], 
            txIDs: txIDs,
            pending: pending, 
            counterparties: counterparties
        })

    }
    next();
})

router.get('/:user_wallet', function (req, res) {
    res.render('escrows/index', {data: data})
})

module.exports = router;