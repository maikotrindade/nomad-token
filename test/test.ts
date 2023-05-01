import { expect } from "chai";
import { ethers } from "hardhat";

describe("NomadToken", function () {
  it("Test contract", async function () {
    const ContractFactory = await ethers.getContractFactory("NomadToken");

    const instance = await ContractFactory.deploy();
    await instance.deployed();

    expect(await instance.name()).to.equal("NomadToken");
  });
});
