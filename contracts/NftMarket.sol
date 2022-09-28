//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}

    // ReentrancyGuard proctect smartcontract from reentrancy attack 
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

    // contract should be pausable for prevent from attacker
contract NftMarket is ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // _ItemsID= Total n. of items of Nfts on this market place.
    Counters.Counter private _ItemsId;

    // _Itemsold= Total n. of Nfts sold at least one times  on this market place.
    Counters.Counter private _Itemsold;

    // Owner of deployer (of smart contract) should immutable
    address private immutable Owner;
    string private constant NULL = "";

    /////// planning to remove listing price later
    uint256 listingPrice = 1 ether;

    constructor() {
        Owner = payable(msg.sender);
    }

    // data of  users history (from ---> to )and its types of events (like-buy, sell, gift ) 
    struct Transaction_Part {
        string Event;
        address _from;
        address _to;
    }
    // track balance of each nft of each users
    mapping (address=>mapping(uint=>uint)) HistoryOfdepositeOfNft;
    event Logwithraw(address indexed,uint price);

    // all information of nft 
    struct MarketItem {
        // Item n. of current Nft on this market place
        uint256 itemId;

        // Contract address of current nft
        address nftContract;

        // Creater of current nft
        address payable creater;

        // Owner of current nft
        address payable Owner;

        // Token Id of current nft
        uint256 TokenId;

        // price of current nft
        uint256 Price;
        // current nft has sold or not atleaft one times
        bool Sold;
        // nft has giftes or not
        bool Gifted;
        // nft has signatured or not by faculty
        string Signature;

        // tracking history of Owner of current nft
        Transaction_Part[] Transaction_History;
    }
    // mapping all Nfts of this market (items n. => history of nft)  
    mapping(uint256 => MarketItem) private IdtoMarketItem;

    // notify at each transaction of nft 
    event MarketCreated(
        address indexed nftContract,
        address indexed Seller,
        address indexed Owner
    );

    // notify when nft has signatured and verify by faculty 
    event Sig_Verified(string Faculty_Name, string e_mail, uint256 Token_Id);

    // planning to remove listing price charge of market and this function too
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Users can create their first Nft on this market
    function CreatMarketItem(
        // address of Nft contract
        address nftContract,
        uint256 Price,
        uint256 tokenId
    ) public payable nonReentrant whenNotPaused {       // function runs when not paused by owner , pausable for security purpose
        require(msg.value > 0, "selling price must be greater than ZERO wei");

        // planning to remove this below condition 
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        // N. of Items increse when any Users creat nft first time
        _ItemsId.increment();
        uint256 ItemId = _ItemsId.current();                //return current n. of total nft items
        MarketItem storage temp = IdtoMarketItem[ItemId];
        // update history of current nft
        temp.itemId = ItemId;
        temp.nftContract = nftContract;
        temp.creater = payable(msg.sender);
        temp.Owner = payable(msg.sender);
        temp.Price = Price;
        temp.TokenId = tokenId;
        temp.Signature = NULL;

        // Transaction history of current history
        temp.Transaction_History.push(
            Transaction_Part("Created", (msg.sender), msg.sender)
        );
        //store price of each Nft crossponding to creator
        HistoryOfdepositeOfNft[msg.sender][ItemId]=Price;

        // pop out notification of successfully created nft on market place, in notification include nft contract , Owner and creater of nft
        emit MarketCreated(nftContract, msg.sender, msg.sender);
    }

    // only Owner of current nft can acess this function
    modifier OnlyOwner(address nftContract, uint256 tokenId) {
        require(
            msg.sender == IERC721(nftContract).ownerOf(tokenId),
            "Only Owner can signed on NFT's"
        );
        _;
    }

        // function for buying nft that listed over market place 
    function creatMarketSale(uint256 ItemId) public payable nonReentrant whenNotPaused {
        // Given Items Id should listed on marketplace
        require(
            _ItemsId.current() >= ItemId,
            "Nothing to buy Nft at this ItemId"
        );
        // acess all information of given ItemId of nfts
        MarketItem storage temp = IdtoMarketItem[ItemId];
        //previous Owner of NFT
        address From = temp.Owner; 
        require(msg.sender!=From,"you're the current owner of this NFT. owner can't purchase own NFT");
        uint256 Price = temp.Price;
        uint256 tokenId = temp.TokenId;
        address nftContract = temp.nftContract;

        // User must have enough money to purchase current nft----cheaking
        require(
            msg.value == Price,
            "please submit the asking price in order to complete the purchase"
        );

        // Update Owner of current nft
        temp.Owner = payable(msg.sender);
        temp.Sold = true;

        // Update history of transation of nft(traking history of transaction)
        temp.Transaction_History.push(
            Transaction_Part("sell/Buy", payable(From), msg.sender)
        );
        // count n. of at least sold nft on market
        _Itemsold.increment();
        // transfer ownership of nft's from previous_owner to current_owner
        IERC721(nftContract).transferFrom(
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            tokenId
        );

        //update store price of each Nft crossponding to creator
        HistoryOfdepositeOfNft[msg.sender][ItemId]=Price;
    }

    function withraw(uint ItemId) public {
         // acess all information of given ItemId of nfts
        MarketItem memory temp = IdtoMarketItem[ItemId];
        
        address current_Owner= temp.Owner;
        require(msg.sender!=current_Owner,"your Nft has not sold yet.");

        //price of withrawal nft 
        uint price=HistoryOfdepositeOfNft[msg.sender][ItemId];

        // update price of nft of crosponding owner
        HistoryOfdepositeOfNft[msg.sender][ItemId]=0;

        // required ETH can withrow after verification of ownership
        (bool sent, ) = payable(msg.sender).call{value: price}("");
        require(sent, "Failed to send Ether to account of Owner of  Nft");
        emit Logwithraw(msg.sender, price);
    } 

    function AddSingnature(
        string memory Faculty_Name,
        string memory _Signature,
        uint256 ItemId
    )
        public
        nonReentrant
        OnlyOwner(
            IdtoMarketItem[ItemId].nftContract,
            IdtoMarketItem[ItemId].TokenId
        )
    {
        MarketItem storage temp = IdtoMarketItem[ItemId];
        temp.Signature = _Signature;
        emit Sig_Verified(Faculty_Name, _Signature, ItemId);
    }

    function GiftNft(address _to, uint256 ItemId) public nonReentrant whenNotPaused {
        MarketItem storage temp = IdtoMarketItem[ItemId];
        require(
            bytes(temp.Signature).length != 0,
            "NFTs is not signatured digitally."
        );
        uint256 tokenId = temp.TokenId;
        address nftContract = temp.nftContract;

        temp.Owner = payable(_to);
        temp.Gifted = true;
        temp.Transaction_History.push(
            Transaction_Part("Gifted", msg.sender, _to)
        );

        IERC721(nftContract).transferFrom(
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            tokenId
        );
    }

    // Owner of SmartContract
    modifier Deployer_OnlyOwner(){
        require(msg.sender==Owner,"You're not actual owner of smartcontract, ACCESS DENIED ");
        _;
    }

    // In case of attaking , Owner can prevent all contract and data by pausing all function by calling this function
    //Triggers stopped state.
    function Pause() public  Deployer_OnlyOwner {
        _pause();
    }

    // after resolve issue , contract Owner can unpause all function
    //Returns to normal state.
    //condition-The contract must be paused.
    function Unpause() public Deployer_OnlyOwner{
        _unpause();
    }

    function fetchUnsoldMarketItems()
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 ItemCount = _ItemsId.current();
        uint256 UnsoldItemCount = SafeMath.sub(
            _ItemsId.current(),
            _Itemsold.current()
        );
        uint256 CurrentIndex = 0;
        MarketItem[] memory Items = new MarketItem[](UnsoldItemCount);
        for (uint256 i = 0; i < ItemCount; i++) {
            if (!IdtoMarketItem[i + 1].Sold) {
                uint256 currentId = IdtoMarketItem[i + 1].itemId;
                MarketItem storage currentItem = IdtoMarketItem[currentId];
                Items[CurrentIndex] = currentItem;
                CurrentIndex = SafeMath.add(CurrentIndex, 1);
            }
        }
        return Items;
    }

    function fetchMyNfts() public view returns (MarketItem[] memory) {
        uint256 ItemCount = _ItemsId.current();
        uint256 CurrentIndex = 0;
        MarketItem[] memory Items = new MarketItem[](CurrentIndex);
        for (uint256 i = 0; i < ItemCount; i++) {
            if (IdtoMarketItem[i + 1].Owner == msg.sender) {
                uint256 currentId = IdtoMarketItem[i + 1].itemId;
                MarketItem storage currentItem = IdtoMarketItem[currentId];
                Items[CurrentIndex] = currentItem;
                CurrentIndex = SafeMath.add(CurrentIndex, 1);
            }
        }
        return Items;
    }

    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 ItemCount = _ItemsId.current();
        uint256 CurrentIndex = 0;
        MarketItem[] memory Items = new MarketItem[](CurrentIndex);
        for (uint256 i = 0; i < ItemCount; i++) {
            if (IdtoMarketItem[i + 1].creater == msg.sender) {
                uint256 currentId = IdtoMarketItem[i + 1].itemId;
                MarketItem storage currentItem = IdtoMarketItem[currentId];
                Items[CurrentIndex] = currentItem;
                CurrentIndex = SafeMath.add(CurrentIndex, 1);
            }
        }
        return Items;
    }

    function fetchNftsGift() public view returns (MarketItem[] memory) {
        uint256 ItemCount = _ItemsId.current();
        uint256 CurrentIndex = 0;
        MarketItem[] memory Items = new MarketItem[](CurrentIndex);
        for (uint256 i = 0; i < ItemCount; i++) {
            if (IdtoMarketItem[i + 1].Gifted == true) {
                uint256 currentId = IdtoMarketItem[i + 1].itemId;
                MarketItem storage currentItem = IdtoMarketItem[currentId];
                Items[CurrentIndex] = currentItem;
                CurrentIndex = SafeMath.add(CurrentIndex, 1);
            }
        }
        return Items;
    }

    function fetchSignNfts() public view returns (MarketItem[] memory) {
        uint256 ItemCount = _ItemsId.current();
        uint256 CurrentIndex = 0;
        MarketItem[] memory Items = new MarketItem[](CurrentIndex);
        for (uint256 i = 0; i < ItemCount; i++) {
            if (bytes(IdtoMarketItem[i + 1].Signature).length != 0) {
                uint256 currentId = IdtoMarketItem[i + 1].itemId;
                MarketItem storage currentItem = IdtoMarketItem[currentId];
                Items[CurrentIndex] = currentItem;
                CurrentIndex = SafeMath.add(CurrentIndex, 1);
            }
        }
        return Items;
    }
}
