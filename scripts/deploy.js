const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const DAO = await hre.ethers.getContractFactory("SimpleDAO");
  const dao = await DAO.deploy(60 * 5); // 5 minutes voting
  await dao.waitForDeployment();
  const daoAddress = await dao.getAddress();
  console.log("DAO deployed to:", daoAddress);

  const Treasury = await hre.ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy(daoAddress);
  await treasury.waitForDeployment();
  const treasuryAddress = await treasury.getAddress();
  console.log("Treasury deployed to:", treasuryAddress);

  const tx = await dao.setTreasury(treasuryAddress);
  await tx.wait();
  console.log("DAO treasury set.");

  console.log("\nCopy these addresses into frontend/index.html:");
  console.log(`const DAO_ADDRESS = "${daoAddress}";`);
  console.log(`const TREASURY_ADDRESS = "${treasuryAddress}";`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
