// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatureBirdNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    constructor() ERC721("MatureBird", "BIRD") Ownable(msg.sender) {}

    function mint(address to, string calldata tokenURI) external onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newId = _tokenIds;
        _safeMint(to, newId);
        _setTokenURI(newId, tokenURI);
        return newId;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
