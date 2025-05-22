const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Decentralized Voting System...");
  
  // Get the contract factory
  const Project = await ethers.getContractFactory("Project");
  
  // Deploy the contract
  console.log("Deploying contract...");
  const project = await Project.deploy();
  
  // Wait for the contract to be deployed
  await project.deployed();
  
  console.log("✅ Decentralized Voting System deployed successfully!");
  console.log("📝 Contract address:", project.address);
  console.log("🔗 Network:", hre.network.name);
  console.log("⛽ Gas used for deployment:", (await project.deployTransaction.wait()).gasUsed.toString());
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("🚀 Deployed by:", deployer.address);
  console.log("💰 Account balance:", ethers.utils.formatEther(await deployer.getBalance()), "CORE");
  
  console.log("\n📋 Contract Functions Available:");
  console.log("- registerVoter(address): Register a new voter (owner only)");
  console.log("- addCandidate(string, string): Add a candidate (owner only)");
  console.log("- vote(uint256): Cast a vote for a candidate");
  console.log("- getCandidate(uint256): Get candidate details");
  console.log("- getCurrentElectionResults(): Get current election results");
  
  // Verify deployment by calling a view function
  try {
    const votersCount = await project.votersCount();
    const candidatesCount = await project.candidatesCount();
    const currentElectionId = await project.currentElectionId();
    
    console.log("\n📊 Initial Contract State:");
    console.log("- Registered Voters:", votersCount.toString());
    console.log("- Total Candidates:", candidatesCount.toString());
    console.log("- Current Election ID:", currentElectionId.toString());
    
    // Get current election details
    const election = await project.getElection(currentElectionId);
    console.log("- Current Election:", election.title);
    console.log("- Election Description:", election.description);
    console.log("- Election Active:", election.active);
    
  } catch (error) {
    console.log("⚠️ Error reading contract state:", error.message);
  }
  
  console.log("\n🎉 Deployment completed successfully!");
  console.log("You can now interact with your Decentralized Voting System contract at:", project.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
