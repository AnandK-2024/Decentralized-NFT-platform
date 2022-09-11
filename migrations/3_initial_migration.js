// const { artifacts } = require("hardhat");

const MyNft = artifacts.require("MyNft");
// error in excess address from 2_initial_migration.js
const address= artifacts.require("./2_initial_migration");
console.log("imported address",address)
module.exports = function (deployer) {
    deployer.deploy(MyNft("iitbhilaitoken","IITBH",address)).then(() => {

    var address=NftMarket.address
    console.log("real address",NftMarket.address,address)

    }
    )
};
