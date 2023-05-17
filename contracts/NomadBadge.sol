// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
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

        // Remove Log
        console.log("%s", svg);

        string memory imageEncoded = Base64.encode(bytes(svg));
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                imageEncoded
            )
        );
    }

    function generateSVG(uint tokenId) internal pure returns (string memory) {
        // TODO 
        // get random number from Chainlink
        uint random = 234;
        uint random10 = (tokenId%10);

        string memory svgTerms = 
        "<svg height='1100' width='1100' xmlns='http://www.w3.org/2000/svg' version='1.1'> ";

        string memory element1 = string(
            abi.encodePacked(
                "<circle cx='", Strings.toString(random%(920-random10)),
                "' cy='", Strings.toString(random%(1020-random10)),
                "' r='", Strings.toString(random%(160-random10)),
                "' stroke='black' stroke-width='3' fill='lawngreen'/>"
            )
        );
        string memory element2 = string(
            abi.encodePacked(
                "<rect x='", Strings.toString(random%(800-random10)),
                "' y='", Strings.toString(random%(900-random10)),
                "' width='", Strings.toString(random%(400-random10)),
                "' height='", Strings.toString(random%(400-random10)),
                "' stroke='black' stroke-width='1' fill='red'/>"
            )
        );
        string memory element3 = string(
            abi.encodePacked(
                "<circle cx='", Strings.toString(random%(910-random10)),
                "' cy='", Strings.toString(random%(1010-random10)),
                "' r='", Strings.toString(random%(150-random10)),
                "' stroke='black' stroke-width='2' fill='teal'/>"
            )
        );

        return string(abi.encodePacked(svgTerms, element1, element2, element3, "</svg>"));
    }

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge functions
    // ----------------------------------------------------------------------------------------------------------------
    function addFlight(uint256 flightId, address passenger) public payable {
        require(_flights[passenger].id != flightId, "Flight already registered");

        _flights[passenger].id = flightId;
        emit FlightAdded(flightId);

        // TODO remove log
        console.log("Adding flight id  = %s to address = %s", flightId , passenger);
    }

    function runRewardProcess(address passenger) public onlyOwner {
        uint256 badgeId = _badgeIdCounter.current();
        require(!_exists(badgeId), "Token already exists");

        _safeMint(passenger, badgeId);
        _badgeIdCounter.increment();
        tokenURI(badgeId);
        _passengers[badgeId].passenger = passenger;

        // TODO remove log
        console.log("Badge generated id = %s to passenger = %s", badgeId, passenger);
    
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
        require(_erc20Token.balanceOf(owner()) >= DEFAULT_REWARD_POINTS, "Insufficient balance");

        // TODO remove log
        console.log(
            "Owner balance = %s",
             _erc20Token.balanceOf(owner())
        ); 

        _erc20Token.allowance(owner(), to);
        _erc20Token.approve(owner(), DEFAULT_REWARD_POINTS);
        
        _erc20Token.transfer(to, DEFAULT_REWARD_POINTS);
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
