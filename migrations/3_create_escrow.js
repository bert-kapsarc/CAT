const CarboTag = artifacts.require("./CarboTag.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboTag.deployed();
    // create escrow wallet
    await instance.createEscrow(accounts[0],{from: accounts[1]});
    // create offerTransaction
    await instance.createTransaction(accounts[0],10000,0,{from: accounts[1]});
    let escrowAddr = await instance.findEscrowAddr(accounts[1], accounts[0]);
    let multisig = await MultiSigWallet.at(escrowAddr);
    console.log(escrowAddr);
    console.log(instance.address); 
    console.log(await instance.transactionData(escrowAddr,0));

    // put some funds in the escrow for tx fees
    //await multisig.send(1e18, {from: accounts[1]});

    // generate encodedFunctionCall
    // to use in external_call to CarboTag contract upon confirmation of multisig tx;
    /*
    let data = web3.eth.abi.encodeFunctionCall({
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "_sender",
          "type": "address"
        }
        ,{
          "internalType": "address",
          "name": "_receiver",
          "type": "address"
        }
        ,{
          "internalType": "uint",
          "name": "tx_id",
          "type": "uint"
        }
        ,
        
        ,{
          "internalType": "int256",
          "name": "carbon",
          "type": "int256"
        }
        ,{
          "internalType": "int256",
          "name": "gold",
          "type": "int256"
        } 
        
      ],
      "name": "offerAccept",
      "outputs": [],
      "payable": true,
      "stateMutability": "payable",
      "type": "function"}, 
      [accounts[1],accounts[0],1,10,0]
    );

    console.log(data);
    let value = "1000000000000000000"; 
    */
    // submit tx with FunctionCall
    //let txID0 = await multisig.submitTransaction(instance.address, value, data, {from: accounts[1]});
    //console.log(txID0);

    //await instance.offerAcceptTag(accounts[1], accounts[0], 1);
    //const result = await web3.eth.send({to: instance.address,data});
    //console.log(result);
}