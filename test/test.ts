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
    const NomadRewardToken = await ethers.getContractFactory("NomadRewardToken")
    erc20Instance = await NomadRewardToken.deploy()
    
    // Deploy NomadBadge
    const NomadBadge = await ethers.getContractFactory("NomadBadge")
    contractInstance = await NomadBadge.deploy(erc20Instance.address)
    await contractInstance.deployed()
  });
  
  it('ERC20: should transfer totalSupply to owner/msg.sender', async function () {
    let totalSupply = await erc20Instance.connect(owner).balanceOf(owner.address)
    expect(totalSupply).equals("100000000000000000000000000000")
  });
  
  it('Soulbound token: should add a flight', async function () {
    let flightId = 12345
    
    let addFlightMethod = contractInstance.connect(owner).addFlight(flightId, owner.address)
    await expect(addFlightMethod).to.emit(contractInstance, 'FlightAdded').withArgs(flightId)
  });
  
  it('Soulbound token: should provide rewards', async function () {
    const rewardsPoints = 1000;
    const initialOwnerBalance = await erc20Instance.connect(owner).balanceOf(owner.address)
    
    const rewardProcessMethod = contractInstance.connect(owner).runRewardProcess(user.address)
    await expect(rewardProcessMethod).to.emit(contractInstance, 'RewardsProvided').withArgs(user.address)
    await expect(rewardProcessMethod).to.emit(contractInstance, 'RewardsPointsAssigned').withArgs("0", user.address, rewardsPoints)
    
    let currentOwnerBalance = await erc20Instance.connect(owner).balanceOf(owner.address)
    let expectedRewards = Number(ethers.utils.formatEther(initialOwnerBalance)) - rewardsPoints
    await expect((currentOwnerBalance).eq(expectedRewards))
  });
  
});
