import { expect } from "chai";
import { ethers } from "hardhat";
import { NomadBadge, NomadRewardToken } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import "@nomicfoundation/hardhat-toolbox";

describe("NomadBadge", function () {
  
  let contractInstance: NomadBadge
  let erc20Instance: NomadRewardToken
  let owner: SignerWithAddress
  let user: SignerWithAddress

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners()

    // Deploy NomadRewardToken
    const NomadRewardToken = await ethers.getContractFactory("NomadRewardToken");
    erc20Instance = await NomadRewardToken.deploy();

    // Deploy NomadBadge
    const NomadBadge = await ethers.getContractFactory("NomadBadge");
    contractInstance = await NomadBadge.deploy(erc20Instance.address);
    await contractInstance.deployed();
  });

  it('should add a flight', async function () {
    let flightId = 12345

    let addFlightMethod = contractInstance.connect(owner).addFlight(flightId, owner.address)
    await expect(addFlightMethod).to.emit(contractInstance, 'FlightAdded').withArgs(flightId);
  });

  it('should provide rewards', async function () {
    let rewardProcessMethod = contractInstance.connect(owner).runRewardProcess(user.address)
    await expect(rewardProcessMethod).to.emit(contractInstance, 'RewardsProvided').withArgs(user.address);
    
    await expect(rewardProcessMethod).to.emit(contractInstance, 'RewardsPointsAssigned').withArgs("0", user.address, 1000);
  });

});
