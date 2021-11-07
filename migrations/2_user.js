const CAT = artifacts.require("./CAT.sol");

module.exports = async (deployer,network, accounts) => {
    let instance = await CAT.deployed();
    //console.log(accounts)
    //send 10 eth to CAT contract
    //await instance.send(10e18, {from: accounts[9]});
    //accounts.forEach(element => await instance.signUp("Owner", {from: element}))
    await instance.signUp("Owner", {from: accounts[0]});
};
