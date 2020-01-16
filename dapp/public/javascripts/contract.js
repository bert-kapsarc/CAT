/*
* connect to ethereum node
*/
const Web3 = require('web3');
//const solc = require('solc');
const rpcURL = process.env.INFURA_ROPSTEN
const web3 = new Web3(rpcURL)

// Assigning to exports will not modify module, must use module.exports
module.exports = class Contract {
    constructor(abi, address){
        this.contract = new web3.eth.Contract(abi, address)
    }
    callFn(fn,attr=null){
        if(attr!==null){
            return this.contract.methods[fn](attr).call(function(err, res){ return res })
        }else{
            return this.contract.methods[fn]().call(function(err, res){ return res })
        }
    }
    sendFn(fn,from,attr=null){
        try {
            if(attr!==null){
                return this.contract.methods[fn](attr).send({from: from},function(err, res){ return res })
            }else{
                return this.contract.methods[fn]().send({from: from}, function(err, res){ return res })
            }
        }catch(e){
            // if user cancel transaction at Metamask UI we'll get error and handle it here
            console.log(e);
            // update progress UI anyway
            //setSubmitting(false);
        }
    }
};