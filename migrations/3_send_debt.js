const CarboDebtDummy = artifacts.require("./CarboDebtDummy.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");
module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboDebtDummy.deployed();
    await instance.createEscrow(accounts[0],{from: accounts[1]});
    let escrow = await instance.escroWallet(accounts[1], accounts[0]);
    let multisig = await MultiSigWallet.at(escrow);
    console.log(escrow);
    // generate data to use in external_call to CarboDebt contract upon confirmation of multisig tx
    // this costs no gas
    let data = await instance.offerTransferDebt(accounts[0],1,{from: accounts[1]});
    // send tx
    let txID = multisig.submitTransaction(instance.address, 0, data, {from: accounts[1]});
    // confirm tx 
    console.log(txID)
    multisig.confirmTransaction(0, {from: accounts[0]});    
}