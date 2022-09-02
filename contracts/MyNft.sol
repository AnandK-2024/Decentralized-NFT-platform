//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// library Counters {
//     struct Counter {
//         uint256 _value; // default: 0
//     }

//     function current(Counter storage counter) internal view returns (uint256) {
//         return counter._value;
//     }

//     function increment(Counter storage counter) internal {
//         unchecked {
//             counter._value += 1;
//         }
//     }
// }

abstract contract MyNft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    constructor(
        string memory _NftName,
        string memory _nftSymbol,
        address MarketPlaceAddress
    ) ERC721(_NftName, _nftSymbol) {
        contractAddress = MarketPlaceAddress;
    }

    function CreatToken(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);

        return newItemId;
    }
}
