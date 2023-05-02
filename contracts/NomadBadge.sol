// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

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
        require(isOwner(badgeId, to) || from == owner(), "Badge token is soulbound");
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
    // Events
    // ----------------------------------------------------------------------------------------------------------------
    event FlightAdded(uint256 _flightId);

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge
    // ----------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) private _flightIds; // by address
    mapping(uint256 => uint256) public rewardPoints; // by badgeId
    uint256 private _defaultPoints = 1000;
    
    function addFlight(uint256 _flightId, address owner) public payable {
        _flightIds[owner] = _flightId;
        emit FlightAdded(_flightId);

        console.log("Adding flight id  = %s to address = %s", _flightId ,owner); // TODO remove log
    }

    function isOwner(uint256 badgeId, address owner) public view returns (bool) {
        return ownerOf(badgeId) == owner;
    }

    function runRewardProcess(address to) public onlyOwner {
        uint256 badgeId = _badgeIdCounter.current();
        require(!_exists(badgeId), "Token already exists");
        _badgeIdCounter.increment();
        _safeMint(to, badgeId);
        assignPoints(badgeId, to, _defaultPoints);
        // TODO transfer ERC20 tokens
        // TODO add events
    }

    function assignPoints(uint256 badgeId, address to, uint256 points) public {
        require(isOwner(badgeId, to), "You can only assign points to your own tokens.");
        rewardPoints[badgeId] = points;
        // TODO add events
    }

    function getPoints(uint256 badgeId) public view returns (uint256) {
        return rewardPoints[badgeId];
    }
}
