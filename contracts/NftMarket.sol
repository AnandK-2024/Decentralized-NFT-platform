//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// library Counters {
//     struct Counter {
//         uint256 _value; // default: 0
//     }

//     function current(Counter storage counter) internal view returns (uint256) {
//         return counter._value;
//     }

//     function increment(Counter storage counter) internal {
//         unchecked {
//             uint256 c = counter._value + 1;
//             require(c >= counter._value, "SafeMath: addition overflow");
//             counter._value += 1;
//         }
//     }
// }

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

contract NftMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _ItemsId;
    Counters.Counter private _Itemsold;
    address payable Owner;
    string private constant NULL = "";
    uint256 listingPrice = 1 ether;

    constructor() {
        Owner = payable(msg.sender);
    }

    struct Transaction_Part {
        string Event;
        address _from;
        address _to;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        address payable creater;
        address payable Owner;
        uint256 TokenId;
        uint256 Price;
        bool Sold;
        bool Gifted;
        string Signature;
        Transaction_Part[] Transaction_History;
    }
    mapping(uint256 => MarketItem) private IdtoMarketItem;

    event MarketCreated(
        // uint256 indexed itemId,
        address indexed nftContract,
        address indexed Seller,
        address indexed Owner
        // uint256 indexed TokenId,
        // uint256 indexed Price,
        // bool Sold
    );

    event Sig_Verified(string Faculty_Name, string e_mail, uint256 Token_Id);

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function CreatMarketItem(
        address nftContract,
        uint256 Price,
        uint256 tokenId
    ) public payable nonReentrant {
        require(msg.value > 0, "selling price must be greater than ZERO wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        _ItemsId.increment();
        uint256 ItemId = _ItemsId.current();
        MarketItem storage temp = IdtoMarketItem[ItemId];
        temp.itemId = ItemId;
        temp.nftContract = nftContract;
        temp.creater = payable(msg.sender);
        temp.Owner = payable(msg.sender);
        temp.Price = Price;
        temp.TokenId = tokenId;
        temp.Signature = NULL;
        temp.Transaction_History.push(
            Transaction_Part("Created", (msg.sender), msg.sender)
        );

        // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        //ERC721 is a standard for representing ownership of non-fungible tokens, that is, where each token is unique. ERC721 is a more complex standard than ERC20, with multiple optional extensions, and is split across a number of contracts.
        emit MarketCreated(
            // ItemId,
            nftContract,
            msg.sender,
            msg.sender
            // tokenId,
            // Price,
            // false
        );
    }

    modifier OnlyOwner(address nftContract, uint256 tokenId) {
        require(
            msg.sender == IERC721(nftContract).ownerOf(tokenId),
            "Only Owner can signed on NFT's"
        );
        _;
    }

    function creatMarketSale(uint256 ItemId) public payable nonReentrant {
        require(
            _ItemsId.current() >= ItemId,
            "Nothing to buy Nft at this ItemId"
        );
        MarketItem storage temp = IdtoMarketItem[ItemId];
        uint256 Price = temp.Price;
        uint256 tokenId = temp.TokenId;
        address nftContract = temp.nftContract;
        require(
            msg.value == Price,
            "please submit the asking price in order to complete the purchase"
        );
        address From = temp.Owner; /////previous Owner of NFT

        temp.Owner = payable(msg.sender);
        temp.Sold = true;
        temp.Transaction_History.push(
            Transaction_Part("sell/Buy", payable(From), msg.sender)
        );
        _Itemsold.increment();
        // ownership of nft's transfer from previous_owner to current_owner
        IERC721(nftContract).transferFrom(
            IERC721(nftContract).ownerOf(tokenId),
            msg.sender,
            tokenId
        );
        (bool sent, ) = payable(From).call{value: msg.value}("");
        require(sent, "Failed to send Ether to previous Owner of  Nft");

        //////price estimate for royality
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

    function GiftNft(address _to, uint256 ItemId) public nonReentrant {
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
