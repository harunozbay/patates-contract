import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-contract-sizer";
import "dotenv/config"

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  defaultNetwork: "mumbai",
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/da8dd5f46bc7418f9228452a6b28dbf2",
      accounts: [process.env.PRIVATE_KEY as string],      
    },
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: false,
    only: ["Potato"],
  }
};

export default config;
