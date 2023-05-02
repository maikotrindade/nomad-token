import { expect } from "chai";
import { ethers } from "hardhat";
import { NomadBadge } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("NomadBadge", function () {
  
  let contractInstance: NomadBadge
  let owner: SignerWithAddress

  beforeEach(async function () {
    const NomadBadge = await ethers.getContractFactory("NomadBadge");
    [owner] = await ethers.getSigners()
    contractInstance = await NomadBadge.deploy();
    await contractInstance.deployed();
  });

  it('should add a flight', async function () {
    let flightId = 12345

    let addFlightMethod = contractInstance.connect(owner).addFlight(flightId, owner.address)
    await expect(addFlightMethod).to.emit(contractInstance, 'FlightAdded').withArgs(flightId);
  });
});
