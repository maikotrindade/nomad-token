import { expect } from "chai";
import { ethers } from "hardhat";
import "@nomicfoundation/hardhat-toolbox";

describe("NomadRewardToken", function () {
  it("Test contract NomadRewardToken creation", async function () {
    const ContractFactory = await ethers.getContractFactory("NomadRewardToken");

    const instance = await ContractFactory.deploy();
    await instance.deployed();

    expect(await instance.name()).to.equal("NomadRewardToken");
  });
});
