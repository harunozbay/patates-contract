import { ethers } from "hardhat";

async function main() {
  const contract = await ethers.deployContract("Potato", ["0xcc9Ae8E9b701A8FD9610C45010aa7d7b0f3567Bf"]);
  await contract.waitForDeployment();
  console.log(`Potato deployed to ${contract.target}`);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
