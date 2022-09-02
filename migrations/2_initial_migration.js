const MyNft = artifacts.require("MyNft");

module.exports = function (deployer) {
  deployer.deploy(MyNft(0xd453aaB6def4dF34283229641cBd6719bbcdbA5E));
};
