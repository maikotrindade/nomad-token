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

    // ----------------------------------------------------------------------------------------------------------------
    // Variables and Struts
    // ----------------------------------------------------------------------------------------------------------------
    Counters.Counter private _badgeIdCounter;
    uint256 public constant DEFAULT_REWARD_POINTS = 1000;
    uint256 private _totalPointsDistributed = 0;
    string[] private _layerPalette;

    enum FlightStatus {
        ACTIVE,
        CANCELLED,
        SCHEDULED,
        UNKNOWN
    }

    struct Flight {
        uint256 id;
        FlightStatus status;
    }

    struct Passenger {
        address passenger;
        uint256 rewardPoints;
    }

    mapping(address => Flight) private _flights; // by passenger address
    mapping(uint256 => Passenger) private _passengers; // by badgeId

    // ----------------------------------------------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------------------------------------------
    event FlightAdded(uint256 _flightId);
    event RewardsProvided(address to);
    event RewardsPointsAssigned(uint256 badgeId, address to, uint256 points);

    // ----------------------------------------------------------------------------------------------------------------
    // Base contract functions
    // ----------------------------------------------------------------------------------------------------------------
    constructor(address erc20Address) ERC721("NomadBadge", "NBG") {
        _erc20Token = IERC20(erc20Address);
    }
    
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
        // TODO 
        // get random number from Chainlink
        uint random = 12345;
        uint random10 = (tokenId%10);
        return string(abi.encodePacked(
                "<svg height='1100' width='1100' xmlns='http://www.w3.org/2000/svg' version='1.1'> ",
                "<circle cx='", Strings.toString(random%(900-random10)),
                "' cy='", Strings.toString(random%(1000-random10)),
                "' r='", Strings.toString(random%(100-random10)),
                "' stroke='black' stroke-width='3' fill='", _layerPalette[random%10],"'/>",

                "<circle cx='", Strings.toString(random%(902-random10)),
                "' cy='", Strings.toString(random%(1002-random10)),
                "' r='", Strings.toString(random%(102-random10)),
                "' stroke='black' stroke-width='3' fill='", _layerPalette[random%8],"'/>",

                "</svg>"
            ));
    }

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge functions
    // ----------------------------------------------------------------------------------------------------------------
    function addFlight(uint256 flightId, address passenger) public payable {
        require(_flights[passenger].id != flightId, "Flight already registered");

        _flights[passenger].id = flightId;
        emit FlightAdded(flightId);

        // TODO remove log
        console.log("Adding flight id  = %s to address = %s", flightId , passenger); // TODO remove log
    }

    function runRewardProcess(address passenger) public onlyOwner {
        uint256 badgeId = _badgeIdCounter.current();
        require(!_exists(badgeId), "Token already exists");

        _badgeIdCounter.increment();
        _safeMint(passenger, badgeId);
        _passengers[badgeId].passenger = passenger;

        // TODO remove log
        console.log("Badge generated id = %s to passenger = %s", badgeId, passenger); // TODO remove log
    
        emit RewardsProvided(passenger);
        assignPoints(badgeId, passenger);
        transferERC20(passenger);
    }

    function isOwner(uint256 badgeId, address owner) public view returns (bool) {
        return ownerOf(badgeId) == owner;
    }

    function assignPoints(uint256 badgeId, address passenger) public {
        require(isOwner(badgeId, passenger), "You can only assign points to your own tokens.");
        _passengers[badgeId].rewardPoints += DEFAULT_REWARD_POINTS;
        _totalPointsDistributed += DEFAULT_REWARD_POINTS;
        emit RewardsPointsAssigned(badgeId, passenger, DEFAULT_REWARD_POINTS);

        // TODO remove log
        console.log(
            "Points assigned = %s | total amount of = %s",
             DEFAULT_REWARD_POINTS, 
             _passengers[badgeId].rewardPoints
        ); 
    }

    function transferERC20(address to) public {
        // TODO not implement yet
        // require(_erc20Token.balanceOf(owner()) >= Rewards.defaultPoints, "Insufficient balance");
        // bool success = _erc20Token.transferFrom(owner(), to, Rewards.defaultPoints);
        // require(success, "ERC20: Transfer failed");
    }

    function getPoints(uint256 badgeId) public view returns (uint256) {
        require (_passengers[badgeId].passenger == address(0), "It was not possible to get rewards points by badgeId.");
        return _passengers[badgeId].rewardPoints;
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
