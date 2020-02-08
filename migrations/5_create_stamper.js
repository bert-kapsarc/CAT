const CarboTag = artifacts.require("./CarboTag.sol");
const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");

module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboTag.deployed();
    
    console.log(await instance.stamperRegistry(accounts[0]));
}