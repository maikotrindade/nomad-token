// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
    
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./NomadRewardToken.sol";
import 'base64-sol/base64.sol';
import "hardhat/console.sol";

contract NomadBadge is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;

    NomadRewardToken private erc20Token;

    // ----------------------------------------------------------------------------------------------------------------
    // Variables and Struts
    // ----------------------------------------------------------------------------------------------------------------
    Counters.Counter private badgeIdCounter;
    uint256 public constant DEFAULT_REWARD_POINTS = 1000;
    uint256 private totalPointsDistributed = 0;

    enum FlightRewardStatus {
        READY,
        CANCELLED,
        SCHEDULED,
        REWARDED,
        UNKNOWN
    }

    struct Flight {
        uint256 id;
        FlightRewardStatus status;
        address passenger;
    }

    struct Passenger {
        address passenger;
        uint256 rewardPoints;
    }

    uint256[] private flightsId;
    mapping(uint256 => Flight) private flights; // by flight Id
    mapping(uint256 => Passenger) private passengers; // by badgeId

    uint256 public updateTimer;
    uint256 public lastTimeStamp;

    // ----------------------------------------------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------------------------------------------
    event FlightAdded(uint256 flightId);
    event FlightStatusUpdated(FlightRewardStatus status);
    event RewardsProvided(address to);
    event RewardsPointsAssigned(uint256 badgeId, address to, uint256 points);

    // ----------------------------------------------------------------------------------------------------------------
    // Base contract functions
    // ----------------------------------------------------------------------------------------------------------------
    constructor(address erc20Address) ERC721("NomadBadge", "NBG") {
        erc20Token = NomadRewardToken(erc20Address);
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

    function tokenURI(uint256 /* badgeId */) public pure override(ERC721, ERC721URIStorage) returns (string memory) {
        return constructTokenURI();
    }

    function constructTokenURI() public pure returns (string memory) {
        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' version='1.1' height='1100' width='1100'>",
            "<circle cx='500' cy='500' r='150' fill='lawngreen' stroke='#001122' stroke-width='2'/>",
            "<rect x='600' y='250' width='350' height='250' fill='teal' />",
            "<polygon points='800,200 950,400 650,400' fill='orange' /> </svg>"
        ));
        string memory imageEncoded = Base64.encode(bytes(svg));
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                imageEncoded
            )
        );
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Chainlink Automation functions
    // ----------------------------------------------------------------------------------------------------------------
    function checkUpkeep(bytes calldata /* checkData */)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */) {
            upkeepNeeded = (block.timestamp - lastTimeStamp) > updateTimer;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        lastTimeStamp = block.timestamp;
        runRewardProcess();
    }

    function setUpdateTimer(uint256 _updateTimer) public onlyOwner {
        updateTimer = _updateTimer;
    }

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge functions
    // ----------------------------------------------------------------------------------------------------------------
    function addFlight(uint256 flightId, address passenger) public payable {
        require(flights[flightId].id != flightId, "Flight already registered");

        flights[flightId] = Flight(flightId, FlightRewardStatus.SCHEDULED, passenger);
        flightsId.push(flightId);
        emit FlightAdded(flightId);

        // TODO remove log
        console.log("Adding flight id = %s to pax address %s", flightId, passenger);
    }

    function updateFlightStatus(uint256 flightId, FlightRewardStatus status) public onlyOwner {
        flights[flightId].status = status;
        emit FlightStatusUpdated(status);
    }

    function runRewardProcess() public onlyOwner {
        for (uint index=0; index < flightsId.length; index++) {
            uint256 flightId = flightsId[index];
            if (flights[flightId].status == FlightRewardStatus.READY) {
                uint256 badgeId = badgeIdCounter.current();
                require(!_exists(badgeId), "Token already exists");

                address passenger = flights[flightId].passenger;
                _safeMint(passenger, badgeId);
                badgeIdCounter.increment();
                tokenURI(badgeId);
                passengers[badgeId].passenger = passenger;

                // TODO remove log
                console.log("Badge generated id = %s to passenger = %s", badgeId, passenger);
            
                emit RewardsProvided(passenger);
                assignPoints(badgeId, passenger);
                transferERC20Rewards(passenger);
            }
        }
    }

    function isOwner(uint256 badgeId, address owner) public view returns (bool) {
        return ownerOf(badgeId) == owner;
    }

    function assignPoints(uint256 badgeId, address passenger) public {
        require(isOwner(badgeId, passenger), "You can only assign points to your own tokens.");
        passengers[badgeId].rewardPoints += DEFAULT_REWARD_POINTS;
        totalPointsDistributed += DEFAULT_REWARD_POINTS;
        emit RewardsPointsAssigned(badgeId, passenger, DEFAULT_REWARD_POINTS);

        // TODO remove log
        console.log(
            "Points assigned = %s | total amount of = %s",
             DEFAULT_REWARD_POINTS, 
             passengers[badgeId].rewardPoints
        ); 
    }

    function transferERC20Rewards(address passenger) private onlyOwner {
        require(erc20Token.balanceOf(owner()) >= DEFAULT_REWARD_POINTS, "Insufficient balance");
        erc20Token.transferRewards(passenger, DEFAULT_REWARD_POINTS);
    }

    function getPoints(uint256 badgeId) public view returns (uint256) {
        require (passengers[badgeId].passenger == address(0), "It was not possible to get rewards points by badgeId.");
        return passengers[badgeId].rewardPoints;
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Dev methods
    // ----------------------------------------------------------------------------------------------------------------
    function getTotalPointsDistributed() public view returns (uint256) {
        return totalPointsDistributed;
    }

    function getTotalBadgesMinted() public view returns (uint256) {
        return badgeIdCounter.current();
    }
}
