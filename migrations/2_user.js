const CarboTag = artifacts.require("./CarboTag.sol");

module.exports = async (deployer,network, accounts) => {
    let instance = await CarboTag.deployed();
    //console.log(accounts)
    //send 10 eth to CarboTag contract
    //await instance.send(10e18, {from: accounts[9]});
    //accounts.forEach(element => await instance.signUp("Owner", {from: element}))
    await instance.signUp("Owner", {from: accounts[0]});
};
