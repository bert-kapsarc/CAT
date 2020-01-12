const CarboTag = artifacts.require("./CarboTag.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboTag.deployed();
    let escrow = await instance.findEscrowAddr(accounts[1], accounts[0]);
    let multisig = await MultiSigWallet.at(escrow);
    
    // confirm tx in multisig escrow
    await multisig.confirmTransaction(0, {from: accounts[1]});
    await multisig.confirmTransaction(0, {from: accounts[0]}); 

    console.log(await multisig.transactions(0));  
    console.log(await instance.wallet(accounts[0]));

    // create stamper
    await instance.stampAdd(accounts[0], true, 1, 0, {from: accounts[0]});    
}