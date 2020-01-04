const CarboDebtDummy = artifacts.require("./CarboDebtDummy.sol");

module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboDebtDummy.deployed();
    for(let i = 0; i < 2; i++){
        await instance.signUp('a', {from: accounts[i]})
        await instance.addDebtToSelf(1, {from: accounts[i]})
    }
};
