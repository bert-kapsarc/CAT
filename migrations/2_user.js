const CarboTag = artifacts.require("./CarboTag.sol");

module.exports = async (deployer) => {
    let accounts = await web3.eth.getAccounts();
    let instance = await CarboTag.deployed();
    //send 10 eth to CarboTag contract
    //await instance.send(10e18, {from: accounts[9]});
    for(let i = 0; i < 2; i++){
        await instance.signUp(i.toString(), {from: accounts[i]})
        //await instance.addTagToSelf(1, {from: accounts[i]})
    }
};
