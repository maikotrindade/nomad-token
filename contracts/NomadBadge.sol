// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NomadBadge is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _badgeIdCounter;
    constructor() ERC721("NomadBadge", "NBG") {}

    // ----------------------------------------------------------------------------------------------------------------
    // Base Contract
    // ----------------------------------------------------------------------------------------------------------------
    function _beforeTokenTransfer(address from, address to, uint256 badgeId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, badgeId, batchSize);
    }

    function _burn(uint256 badgeId) internal override(ERC721) {
        super._burn(badgeId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge
    // ----------------------------------------------------------------------------------------------------------------
    function safeMint(address to) public onlyOwner {
        uint256 badgeId = _badgeIdCounter.current();
        _badgeIdCounter.increment();
        _safeMint(to, badgeId);
    }
}
