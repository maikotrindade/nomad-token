require('dotenv').config();
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const alchemySepoliaUrl: string = process.env.ALCHEMY_SEPOLIA_URL!;
const privateKey: string = process.env.PRIVATE_KEY!;
const etherscanKey = process.env.ETHERSCAN_KEY;

const config: HardhatUserConfig = {

  networks: {
    sepolia: {
      url: alchemySepoliaUrl,
      accounts: [privateKey]
    }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    },
  },
  etherscan: {
    apiKey: etherscanKey
  }
};

export default config;
