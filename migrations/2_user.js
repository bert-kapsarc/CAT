const CarboDebtDummy = artifacts.require("./CarboDebtDummy.sol");

module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboDebtDummy.deployed();
    //send 10 eth to CarboDebt contract
    await instance.send(10e18, {from: accounts[9]});
    for(let i = 0; i < 2; i++){

        await instance.signUp(i.toString(), {from: accounts[i]})
        await instance.addDebtToSelf(1, {from: accounts[i]})
    }
};
