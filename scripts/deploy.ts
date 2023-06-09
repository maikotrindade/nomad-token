import { artifacts, ethers } from "hardhat";
import { NomadBadge, NomadRewardToken } from "../typechain-types";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);

  const NomadRewardToken = await ethers.getContractFactory("NomadRewardToken");
  const rewardToken = await NomadRewardToken.deploy();
  await rewardToken.deployed();
  console.log("NomadRewardToken deployed at: " + rewardToken.address);

  const NomadBadge = await ethers.getContractFactory("NomadBadge");
  const nomadBadge = await NomadBadge.deploy(rewardToken.address);
  await nomadBadge.deployed();
  console.log("NomadBadge deployed at: " + nomadBadge.address);

  generateJson(rewardToken, "NomadRewardToken")
  generateJson(nomadBadge, "NomadBadge")

  setupChainlinkAutomation(nomadBadge)
}

function generateJson(instance: NomadRewardToken | NomadBadge, contractName: string) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../output/";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + `/${contractName}Address.json`,
    JSON.stringify({ Contract: instance.address }, undefined, 2)
  );

  const Artifact = artifacts.readArtifactSync(contractName);

  fs.writeFileSync(
    contractsDir + `/${contractName}Abi.json`,
    JSON.stringify(Artifact, null, 2)
  );
}

async function setupChainlinkAutomation(contract: NomadBadge) {
  const updateTimerInSeconds = 60 * 60; // one hour
  await contract.setUpdateTimer(updateTimerInSeconds);
  console.log("Chainlink automation update timer was set to: " + updateTimerInSeconds + " seconds");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
