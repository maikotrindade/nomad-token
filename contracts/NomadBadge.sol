// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NomadBadge is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    IERC20 private _erc20Token;

    Counters.Counter private _badgeIdCounter;
    constructor(address erc20Address) ERC721("NomadBadge", "NBG") {
        _erc20Token = IERC20(erc20Address);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Base Contract
    // ----------------------------------------------------------------------------------------------------------------
    function _beforeTokenTransfer(address from, address to, uint256 badgeId, uint256 batchSize) 
        internal 
        override(ERC721, ERC721Enumerable) virtual {
            require(from == address(0), "Badge token is soulbound"); 
            super._beforeTokenTransfer(from, to, badgeId, batchSize);  
        }
        
    function _burn(uint256 badgeId) internal override(ERC721) {
        super._burn(badgeId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------------------------------------------
    event FlightAdded(uint256 _flightId);
    event RewardsProvided(address to);
    event RewardsPointsAssigned(uint256 badgeId, address to, uint256 points);

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge
    // ----------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) private _flightIds; // by address
    mapping(uint256 => address) private _owners; // by badgeId
    mapping(uint256 => uint256) public rewardPoints; // by badgeId
    uint256 private _defaultPoints = 1000;
    
    function addFlight(uint256 _flightId, address owner) public payable {
        require(_flightIds[owner] != _flightId, "Flight already registered");

        _flightIds[owner] = _flightId;
        emit FlightAdded(_flightId);
        console.log("Adding flight id  = %s to address = %s", _flightId , owner); // TODO remove log
    }

    function isOwner(uint256 badgeId, address owner) public view returns (bool) {
        return ownerOf(badgeId) == owner;
    }

    function runRewardProcess(address to) public onlyOwner {
        uint256 badgeId = _badgeIdCounter.current();
        require(!_exists(badgeId), "Token already exists");

        _badgeIdCounter.increment();
        _safeMint(to, badgeId);
        _owners[badgeId] = to;
        console.log("Badge generated id = %s to address = %s", badgeId, to); // TODO remove log
    
        emit RewardsProvided(to);
        assignPoints(badgeId, to, _defaultPoints);
        //TODO transferERC20(to, _defaultPoints);
    }

    function assignPoints(uint256 badgeId, address to, uint256 points) public {
        require(isOwner(badgeId, to), "You can only assign points to your own tokens.");
        rewardPoints[badgeId] += points;
        emit RewardsPointsAssigned(badgeId, to, points);
        console.log("Points assigned = %s | total amount of = %s", points, rewardPoints[badgeId]); // TODO remove log
    }

    // function transferERC20(address to, uint256 amount) public {
    //     require(_erc20Token.balanceOf(owner()) >= amount, "Insufficient balance");
    //     bool success = _erc20Token.transferFrom(owner(), to, amount);
    //     require(success, "ERC20: Transfer failed");
    // }

    function getPoints(uint256 badgeId) public view returns (uint256) {
        return rewardPoints[badgeId];
    }
}
