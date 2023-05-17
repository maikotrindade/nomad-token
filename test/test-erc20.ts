import { expect } from "chai";
import { ethers } from "hardhat";
import { NomadBadge, NomadRewardToken } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import "@nomicfoundation/hardhat-toolbox";

describe("NomadRewardToken", function () {

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

  it('should transfer totalSupply to owner/msg.sender', async function () {
    let totalSupply = await erc20Instance.connect(owner).balanceOf(owner.address)
    expect(totalSupply).equals("100000000000000000000000000000");
  });

});
