// const { artifacts } = require("hardhat");

// const { artifacts } = require("hardhat");
// const Migrations = artifacts.require("Migrations");

const NftMarket = artifacts.require("NftMarket");
const MyNft = artifacts.require('MyNft')
// error in excess address from 2_initial_migration.js
// console.log("imported address",address)
module.exports = async function (deployer) {
    var address;
    await deployer.deploy(NftMarket).then(() => {

    address = NftMarket.address
    console.log("this is the address of the NFTMarkewt",address)
    })
    console.log("contract 2 is deployed. Now starting 3 with address", address)
    deployer.deploy(MyNft("iitbhilaitoken","IITBH",address)).then(() => {

    console.log("real address",NftMarket.address,address)

    }
    )
};
