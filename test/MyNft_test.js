const {assert} =require('chai')
const { artifacts, ethers } = require('hardhat')
const MyNft= artifacts.require('./MyNft.sol')
describe('MyNft', function(){
    let contract;
    before (async()=>{
        const contract=await ethers.getContractFactory('contracts')
        contract = await contract.deploy();
        await contract.deploy();
    });

    it('should create ERC721 token of IIT Bhilai', async()=>{
        const item_Id_1= await contract.creatToken('www.iitbhilai.ac.in')
        assert.equal(item_Id.toNumber()==1, 'test fail for creating item id of tokens')

        const item_Id_2= await contract.creatToken('www.iitbhilai.ac.in')
        assert.equal(item_Id.toNumber()==2,'test fail for creating item id of tokens')

    })

})
