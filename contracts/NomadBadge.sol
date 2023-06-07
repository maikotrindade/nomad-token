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

contract NomadBadge is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;

    NomadRewardToken private immutable erc20Token;

    // ----------------------------------------------------------------------------------------------------------------
    // Variables and Struts
    // ----------------------------------------------------------------------------------------------------------------
    Counters.Counter private badgeIdCounter;
    uint256 public constant DEFAULT_REWARD_POINTS = 1500;
    uint256 private totalPointsDistributed = 0;

    enum FlightRewardStatus {
        SCHEDULED,
        ACTIVE,
        LANDED,
        CANCELLED,
        INCIDENT,
        DIVERTED
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
    event UpkeepPerformed(uint256 lastTimeStamp);

    // ----------------------------------------------------------------------------------------------------------------
    // Base contract functions
    // ----------------------------------------------------------------------------------------------------------------
    constructor(address erc20Address) ERC721("NomadBadge", "NBG") {
        erc20Token = NomadRewardToken(erc20Address);
    }
    
    /**
     * the token is being issued or minted and not transferred according to Soubound token specs
     * @param from payer
     * @param to receiver
     * @param badgeId id of the soulbound token
     * @param batchSize part of a consecutive (batch) mint
     */
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

    /**
     * Perform conditional execution of `runRewardProcess()` method 
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStamp) > updateTimer ) {
            lastTimeStamp = block.timestamp;
            runRewardProcess();
        }
        emit UpkeepPerformed(lastTimeStamp);
    }

    function setUpdateTimer(uint256 _updateTimer) public onlyOwner {
        updateTimer = _updateTimer;
    }

    // ----------------------------------------------------------------------------------------------------------------
    // NomadBadge functions
    // ----------------------------------------------------------------------------------------------------------------

    /**
     * Add flight/passenger details
     * The contract will check the data in order to provide rewards when FlightRewardStatus changes
     * @param flightId id of the flight
     */
    function addFlight(uint256 flightId) public payable {
        require(flights[flightId].id != flightId, "Flight already registered");

        flights[flightId] = Flight(flightId, FlightRewardStatus.SCHEDULED, msg.sender);
        flightsId.push(flightId);
        emit FlightAdded(flightId);
    }

    /**
     * Update the flight status for a specific flight
     * @param flightId id of the flight
     * @param status actual status of the flight
     */
    function updateFlightStatus(uint256 flightId, FlightRewardStatus status) public onlyOwner {
        flights[flightId].status = status;
        emit FlightStatusUpdated(status);
    }

    /**
     * Verify all the flights which are under FlightRewardStatus.READY and provide the rewards points and ERC20 tokens
     * This method is triggered by Chainlink Automation every X time based on Chainlink's configuration 
     */
    function runRewardProcess() public onlyOwner {
        for (uint index=0; index < flightsId.length; index++) {
            uint256 flightId = flightsId[index];
            if (flights[flightId].status == FlightRewardStatus.ACTIVE) {
                uint256 badgeId = badgeIdCounter.current();
                require(!_exists(badgeId), "Token already exists");

                address passenger = flights[flightId].passenger;
                _safeMint(passenger, badgeId);
                badgeIdCounter.increment();
                tokenURI(badgeId);
                passengers[badgeId].passenger = passenger;

                emit RewardsProvided(passenger);
                assignPoints(badgeId, passenger);
                transferERC20Rewards(passenger);
            }
        }
    }

    function isOwner(uint256 badgeId, address owner) public view returns (bool) {
        return ownerOf(badgeId) == owner;
    }

    /**
     * Provide rewards points to the passenger
     * @param badgeId id of the soulbound token
     * @param passenger address of the passenger
     */
    function assignPoints(uint256 badgeId, address passenger) public {
        require(isOwner(badgeId, passenger), "You can only assign points to your own tokens.");
        passengers[badgeId].rewardPoints += DEFAULT_REWARD_POINTS;
        totalPointsDistributed += DEFAULT_REWARD_POINTS;
        emit RewardsPointsAssigned(badgeId, passenger, DEFAULT_REWARD_POINTS);
    }

    /**
     * Provide rewards ERC20 tokens to the passenger
     * @param passenger address of the passenger
     */
    function transferERC20Rewards(address passenger) private onlyOwner {
        uint256 amount = DEFAULT_REWARD_POINTS * 10**14;
        require(erc20Token.balanceOf(owner()) >= amount, "Insufficient balance");
        erc20Token.transferRewards(passenger, amount);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Dev methods
    // ----------------------------------------------------------------------------------------------------------------
    
    /**
     * @return badgeId id of the soulbound token
     */
    function getBadgeId() external view returns (uint256) {
        uint256 badgeCount = balanceOf(msg.sender);
        require(badgeCount > 0, "No token owned by sender");

        uint256 badgeId = tokenOfOwnerByIndex(msg.sender, 0);
        return badgeId;
    }

    /**
     * @param passenger address of the passenger 
     * @return rewardPoints rewards points of the soulbound token
     */
    function getPoints(address passenger) public view returns (uint256) {
        require(balanceOf(passenger) > 0, "No token owned by sender");
        uint256 badgeId = tokenOfOwnerByIndex(passenger, 0);

        require (passengers[badgeId].passenger == address(0), "It was not possible to get rewards points by badgeId.");
        return passengers[badgeId].rewardPoints;
    }

    /**
     * @param passenger address of the passenger 
     * @return rewardTokens rewards ERC20 tokens
     */
    function getTokensRewards(address passenger) public view returns (uint256) {
        uint256 rewardTokens = balanceOf(passenger);
        require(rewardTokens > 0, "No token owned by sender");
        return rewardTokens;
    }

    /**
     * @return scheduledFlights all flightsIds from flights which are Scheduled 
     */
    function getScheduledFlights() public onlyOwner view returns (uint256[] memory) {
        uint256[] memory tempFlights = new uint256[](flightsId.length);
        uint256 counter = 0;

        for (uint index=0; index < flightsId.length; index++) {
            uint256 flightId = flightsId[index];
            if (flights[flightId].status == FlightRewardStatus.SCHEDULED) {
                tempFlights[counter] = flightsId[index];
                counter++;
            }
        }

        // Optimize scheduledFlights
        uint256[] memory scheduledFlights = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            scheduledFlights[i] = tempFlights[i];
        }

        return scheduledFlights;
    }

    function getTotalPointsDistributed() public view returns (uint256) {
        return totalPointsDistributed;
    }

    function getTotalBadgesMinted() public view returns (uint256) {
        return badgeIdCounter.current();
    }

}
