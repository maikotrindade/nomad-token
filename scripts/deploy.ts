import { ethers } from "hardhat";

async function main() {
  const ContractFactory = await ethers.getContractFactory("FlightRewardProgram");

  const instance = await ContractFactory.deploy();
  await instance.deployed();

  console.log(`Contract deployed to ${instance.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
