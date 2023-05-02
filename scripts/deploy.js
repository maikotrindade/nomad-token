import { artifacts, ethers } from "hardhat";

async function main() {
  const NomadBadge = await ethers.getContractFactory("NomadBadge");
  const instance = await NomadBadge.deploy();
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account: " + deployer.address);

  await instance.deployed();
  console.log(`Contract deployed to ${instance.address}`);

  generateJson(instance)
}

function generateJson(instance) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../contract/";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    JSON.stringify({ Contract: instance.address }, undefined, 2)
  );

  const NomadBadgeArtifact = artifacts.readArtifactSync("NomadBadge");

  fs.writeFileSync(
    contractsDir + "/contract.json",
    JSON.stringify(NomadBadgeArtifact, null, 2)
  );
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
