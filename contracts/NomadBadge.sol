// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import 'base64-sol/base64.sol';
import "hardhat/console.sol";

contract NomadBadge is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    IERC20 private _erc20Token;
    string[] layerPalette;

    Counters.Counter private _badgeIdCounter;
    constructor(address erc20Address) ERC721("NomadBadge", "NBG") {
        _erc20Token = IERC20(erc20Address);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------------------------------------------
    event FlightAdded(uint256 _flightId);
    event RewardsProvided(address to);
    event RewardsPointsAssigned(uint256 badgeId, address to, uint256 points);

    // ----------------------------------------------------------------------------------------------------------------
    // Base Contract
    // ----------------------------------------------------------------------------------------------------------------
    function _beforeTokenTransfer(address from, address to, uint256 badgeId, uint256 batchSize) 
        internal 
        override(ERC721, ERC721Enumerable) virtual {
            require(from == address(0), "Badge token is soulbound"); 
            super._beforeTokenTransfer(from, to, badgeId, batchSize);  
        }
        
    function _burn(uint256 badgeId) internal override(ERC721, ERC721URIStorage) {
        super._burn(badgeId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 badgeId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return constructTokenURI(badgeId);
    }

    function constructTokenURI(uint256 badgeId) public view returns (string memory) {
        string memory svg = generateSVG(badgeId);
        string memory imageEncoded = Base64.encode(bytes(svg));
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                imageEncoded
            )
        );
    }

    function generateSVG(uint tokenId) internal view returns (string memory) {
        // TODO get random number from Chainlink
        uint random = 12345;
        uint random10 = (tokenId%10);
        return string(abi.encodePacked(
                "<svg height='1100' width='1100' xmlns='http://www.w3.org/2000/svg' version='1.1'> ",
                "<circle cx='", Strings.toString(random%(900-random10)),
                "' cy='", Strings.toString(random%(1000-random10)),
                "' r='", Strings.toString(random%(100-random10)),
                "' stroke='black' stroke-width='3' fill='", layerPalette[random%10],"'/>",

                "<circle cx='", Strings.toString(random%(902-random10)),
                "' cy='", Strings.toString(random%(1002-random10)),
                "' r='", Strings.toString(random%(102-random10)),
                "' stroke='black' stroke-width='3' fill='", layerPalette[random%8],"'/>",

                "</svg>"
            ));
    }

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge
    // ----------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) private _flightIds; // by address
    mapping(uint256 => address) private _owners; // by badgeId
    mapping(uint256 => uint256) public rewardPoints; // by badgeId
    uint256 private _totalPointsDistributed = 0;
    uint256 private _defaultPoints = 1000;
    
    function addFlight(uint256 _flightId, address owner) public payable {
        require(_flightIds[owner] != _flightId, "Flight already registered");

        _flightIds[owner] = _flightId;
        emit FlightAdded(_flightId);
        console.log("Adding flight id  = %s to address = %s", _flightId , owner); // TODO remove log
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

    function isOwner(uint256 badgeId, address owner) public view returns (bool) {
        return ownerOf(badgeId) == owner;
    }

    function assignPoints(uint256 badgeId, address to, uint256 points) public {
        require(isOwner(badgeId, to), "You can only assign points to your own tokens.");
        rewardPoints[badgeId] += points;
        _totalPointsDistributed += points;
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

    // ----------------------------------------------------------------------------------------------------------------
    // Dev methods
    // ----------------------------------------------------------------------------------------------------------------
    function getTotalPointsDistributed() public view returns (uint256) {
        return _totalPointsDistributed;
    }

    function getTotalBadgesMinted() public view returns (uint256) {
        return _badgeIdCounter.current();
    }
}
