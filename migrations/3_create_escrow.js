const CarboDebtDummy = artifacts.require("./CarboDebtDummy.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboDebtDummy.deployed();
    // create escrow wallet
    await instance.createEscrow(accounts[0],{from: accounts[1]});
    let escrow = await instance.escroWallet(accounts[1], accounts[0]);
    let multisig = await MultiSigWallet.at(escrow);

    console.log(escrow);
    console.log(instance.address); 

    // put some finds in the escrow for tx fees
    await multisig.send(1e18, {from: accounts[1]});

    // generate encodedFunctionCall
    // to use in external_call to CarboDebt contract upon confirmation of multisig tx;
    let data = web3.eth.abi.encodeFunctionCall({
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "_sender",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "_receiver",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "debt",
          "type": "uint256"
        }
      ],
      "name": "offerAcceptDebt",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"}, 
      [accounts[1], accounts[0], '1']);

    console.log(data);
    let value = "1000000000000000000"; 
    // submit tx with FunctionCall
    let txID0 = await multisig.submitTransaction(instance.address, value, data, {from: accounts[1]});
    //console.log(txID0);

    //await instance.offerAcceptDebt(accounts[1], accounts[0], 1);
    //const result = await web3.eth.send({to: instance.address,data});
    //console.log(result);
}