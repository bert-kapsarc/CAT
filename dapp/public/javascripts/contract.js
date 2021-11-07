/*
* connect to ethereum node
*/
const Web3 = require('web3');
//const solc = require('solc');
const rpcURL = process.env.NETWORK_URL
const web3 = new Web3(rpcURL)

// Assigning to exports will not modify module, must use module.exports
module.exports = class Contract {
    constructor(abi, address){

        this.contract = new web3.eth.Contract(abi, address)
    }
    getFn(fn,attr){
        if(attr==null){attr = [];}
        else if (!Array.isArray(attr)){
            attr = [attr]
        }
        return this.contract.methods[fn](...attr)
    }
    encodeFn(fn,attr=null){
        return this.getFn(fn,attr).encodeABI();
    }
    callFn(fn,attr=null){
        return this.getFn(fn,attr).call(function(err, res){ return res })
    }
    // DO we need this?
    sendFn(fn,from,attr=null){
        try {
            this.getFn(fn,attr).send({from: from},function(err, res){ return res })
        }catch(e){
            // if user cancel transaction at Metamask UI we'll get error and handle it here
            console.log(e);
            // update progress UI anyway
            //setSubmitting(false);
        }
    }
};