const CarboDebt = artifacts.require("./CarboDebt.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboDebt.deployed();
    let escrow = await instance.escrowAddr(accounts[1], accounts[0]);
    let multisig = await MultiSigWallet.at(escrow);
    
    // confirm tx in multisig escrow
    multisig.confirmTransaction(0, {from: accounts[0]}); 

    console.log(await multisig.transactions(0));  
    console.log(await instance.wallet(accounts[0]));    
}