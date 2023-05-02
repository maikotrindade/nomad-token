import { expect } from "chai";
import { ethers } from "hardhat";

describe("NomadBadge", function () {
  it("Test contract NomadBadge creation", async function () {
    const ContractFactory = await ethers.getContractFactory("NomadBadge");

    const instance = await ContractFactory.deploy();
    await instance.deployed();

    expect(await instance.name()).to.equal("NomadBadge");
  });
});
