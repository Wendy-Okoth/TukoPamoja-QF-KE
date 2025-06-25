const { ethers } = require("hardhat");

async function main() {
    // Get deployer and a second contributor account
    const [deployer, contributor2] = await ethers.getSigners();
    console.log("Interacting with contracts using account:", deployer.address);
    console.log("Second contributor account:", contributor2.address);

    // IMPORTANT: These are the addresses from your LAST LOCAL DEPLOYMENT (npx hardhat run scripts/deploy.js --network localhost)
    // If you restart 'npx hardhat node' or redeploy locally, these addresses will change!
    const ATTESTATION_SERVICE_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
    const PROJECT_REGISTRY_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
    const QUADRATIC_FUNDING_ADDRESS = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
    const CUSD_TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // This is your Mock cUSD address from local deployment

    // Get contract instances (connected to the deployer for sending transactions)
    const attestationService = await ethers.getContractAt("AttestationService", ATTESTATION_SERVICE_ADDRESS, deployer);
    const projectRegistry = await ethers.getContractAt("ProjectRegistry", PROJECT_REGISTRY_ADDRESS, deployer);
    const quadraticFunding = await ethers.getContractAt("QuadraticFunding", QUADRATIC_FUNDING_ADDRESS, deployer);

    // --- Grant 'Artist' Attestation ---
    console.log("\n--- Granting 'Artist' Attestation ---");
    const attestationType = "Artist";
    const attestationHash = ethers.keccak256(ethers.toUtf8Bytes(`Artist_Attestation_${deployer.address}_${Date.now()}`));

    try {
        const isDeployerAnAttestor = await attestationService.isAttestor(deployer.address);
        if (!isDeployerAnAttestor) {
            console.log(`Deployer ${deployer.address} is not an attestor. Adding as attestor...`);
            const addAttestorTx = await attestationService.addAttestor(deployer.address);
            await addAttestorTx.wait();
            console.log(`Deployer ${deployer.address} added as attestor! Tx Hash: ${addAttestorTx.hash}`);
        } else {
            console.log(`Deployer ${deployer.address} is already an attestor.`);
        }

        const hasArtistAttestation = await attestationService.hasAttestationType(deployer.address, attestationType);
        if (!hasArtistAttestation) {
            console.log(`Issuing '${attestationType}' attestation to ${deployer.address}...`);
            const issueTx = await attestationService.issueAttestation(deployer.address, attestationType, attestationHash);
            await issueTx.wait();
            console.log(`'${attestationType}' attestation issued to ${deployer.address}! Tx Hash: ${issueTx.hash}`);
        } else {
            console.log(`Deployer ${deployer.address} already has '${attestationType}' attestation.`);
        }

        const verifiedAttestation = await attestationService.hasAttestationType(deployer.address, attestationType);
        console.log(`Does ${deployer.address} have '${attestationType}' attestation? ${verifiedAttestation}`);

    } catch (error) {
        console.error("Error with 'Artist' attestation process:", error.message);
        return;
    }


    // --- Interact with ProjectRegistry ---
    console.log("\n--- Interacting with ProjectRegistry ---");
    const projectName = "My Awesome Art Project";
    const projectDescriptionCID = "QmWmgj5xH1B6B2P4H5J6K7L8M9N0O1P2Q3R4S5T6U7V8W9X0Y1Z2";
    const projectCategory = "Art & Culture";

    let submittedProjectId;

    try {
        console.log(`Submitting project "${projectName}"...`);
        const submitTx = await projectRegistry.submitProject(
            projectName,
            projectDescriptionCID,
            projectCategory
        );
        const receipt = await submitTx.wait();
        console.log(`Project "${projectName}" submitted! Tx Hash: ${submitTx.hash}`);

        const projectSubmittedEvent = receipt.logs.find(log => projectRegistry.interface.parseLog(log)?.name === "ProjectSubmitted");

        if (projectSubmittedEvent) {
            submittedProjectId = projectRegistry.interface.parseLog(projectSubmittedEvent).args.id;
            console.log(`Successfully retrieved new Project ID from event: ${submittedProjectId}`);
        } else {
            console.error("ProjectSubmitted event not found. Falling back to last active project ID.");
            const allActiveProjects = await projectRegistry.getAllActiveProjects();
            if (allActiveProjects.length > 0) {
                submittedProjectId = allActiveProjects[allActiveProjects.length - 1].id;
                console.log(`Fallback Project ID: ${submittedProjectId}`);
            } else {
                console.error("No active projects found. Cannot proceed without a project ID.");
                return;
            }
        }

        if (submittedProjectId) {
            const projectDetails = await projectRegistry.getProject(submittedProjectId);
            console.log(`Project Details for ID ${submittedProjectId}:`, {
                id: projectDetails.id.toString(),
                owner: projectDetails.owner,
                name: projectDetails.name,
                descriptionCID: projectDetails.descriptionCID,
                category: projectDetails.category,
                isActive: projectDetails.isActive
            });
        }

        const allActiveProjects = await projectRegistry.getAllActiveProjects();
        console.log("All Active Projects Count:", allActiveProjects.length);

    } catch (error) {
        console.error("Error interacting with ProjectRegistry:", error.message);
        return;
    }


    // --- Interact with QuadraticFunding ---
    console.log("\n--- Interacting with QuadraticFunding ---");

    try {
        // Corrected: Use "MockERC20" for the contract that has the 'mint' function
        const mockTokenContract = await ethers.getContractAt(
            "MockERC20", // <--- THIS IS THE FIX: Changed from "MockcUSD" to "MockERC20"
            CUSD_TOKEN_ADDRESS,
            deployer // Deployer is signer for minting and other deployer-side interactions
        );

        // For general ERC20 operations like balanceOf and approve,
        // we can use the generic IERC20 interface, connected to the appropriate signer.
        // The MockERC20 contract implements IERC20, so these will work.
        const CUSD_Deployer = await ethers.getContractAt("IERC20", CUSD_TOKEN_ADDRESS, deployer);
        const CUSD_Contributor2 = await ethers.getContractAt("IERC20", CUSD_TOKEN_ADDRESS, contributor2);


        // --- A. Setup Funding Round & Initial Contributions ---
        console.log("\n--- A. Setting up Round & Initial Contributions ---");

        // Mint cUSD for contributor2 if needed (assuming deployer can mint)
        const contributor2CUSDBalance = await CUSD_Contributor2.balanceOf(contributor2.address);
        const mintAmount = ethers.parseUnits("500", 18); // Mint 500 cUSD for contributor2
        if (contributor2CUSDBalance < mintAmount) {
            console.log(`Minting ${ethers.formatUnits(mintAmount, 18)} cUSD for Contributor 2 (${contributor2.address})...`);
            try {
                // Use the 'mockTokenContract' instance that has the 'mint' function accessible
                const mintTx = await mockTokenContract.mint(contributor2.address, mintAmount);
                await mintTx.wait();
                console.log("Minting for Contributor 2 successful! Tx Hash:", mintTx.hash);
            } catch (mintError) {
                console.warn(`Could not mint cUSD for Contributor 2: ${mintError.message}. Make sure MockERC20 has a mint function and it's callable by the deployer.`);
            }
        }


        // 1. Start the Funding Round
        const isRoundActive = await quadraticFunding.roundActive();
        if (!isRoundActive) {
            console.log("Starting a new funding round...");
            const startRoundTx = await quadraticFunding.startRound();
            await startRoundTx.wait();
            console.log("Funding round started! Tx Hash:", startRoundTx.hash);
        } else {
            console.log("Funding round is already active.");
        }

        // 2. Deposit Matching Funds (using native ETH/CELO, not cUSD)
        const matchingFundsAmountETH = ethers.parseEther("0.1"); // Deposit 0.1 native token (ETH on localhost)
        console.log(`Depositing ${ethers.formatEther(matchingFundsAmountETH)} native token as matching funds...`);
        const depositTx = await quadraticFunding.depositMatchingFunds({ value: matchingFundsAmountETH });
        await depositTx.wait();
        console.log("Matching funds deposited! Tx Hash:", depositTx.hash);

        // 3. Deployer (Project Owner) Contributes
        const deployerContributionAmount = ethers.parseUnits("1", 18); // 1 cUSD contribution from deployer
        const deployerCUSDApproval = await CUSD_Deployer.approve(QUADRATIC_FUNDING_ADDRESS, deployerContributionAmount);
        await deployerCUSDApproval.wait();
        console.log(`Deployer approved ${ethers.formatUnits(deployerContributionAmount, 18)} cUSD.`);

        console.log(`Deployer (${deployer.address}) attempting to contribute ${ethers.formatUnits(deployerContributionAmount, 18)} cUSD to project ${submittedProjectId}...`);
        const deployerContributeTx = await quadraticFunding.contribute(submittedProjectId, deployerContributionAmount);
        await deployerContributeTx.wait();
        console.log(`Deployer's contribution successful! Tx Hash: ${deployerContributeTx.hash}`);

        // 4. Second Contributor Contributes
        const contributor2ContributionAmount = ethers.parseUnits("2", 18); // 2 cUSD contribution from contributor2
        const contributor2CUSDApproval = await CUSD_Contributor2.approve(QUADRATIC_FUNDING_ADDRESS, contributor2ContributionAmount);
        await contributor2CUSDApproval.wait();
        console.log(`Contributor 2 approved ${ethers.formatUnits(contributor2ContributionAmount, 18)} cUSD.`);

        // Connect QuadraticFunding with contributor2's signer for their contribution
        const quadraticFunding_Contributor2 = await ethers.getContractAt("QuadraticFunding", QUADRATIC_FUNDING_ADDRESS, contributor2);
        console.log(`Contributor 2 (${contributor2.address}) attempting to contribute ${ethers.formatUnits(contributor2ContributionAmount, 18)} cUSD to project ${submittedProjectId}...`);
        const contributor2ContributeTx = await quadraticFunding_Contributor2.contribute(submittedProjectId, contributor2ContributionAmount);
        await contributor2ContributeTx.wait();
        console.log(`Contributor 2's contribution successful! Tx Hash: ${contributor2ContributeTx.hash}`);

        console.log("\n--- B. Pre-Distribution State ---");
        // Get project owner details
        const projectDetails = await projectRegistry.getProject(submittedProjectId);
        const projectOwnerAddress = projectDetails.owner;

        // Query balances and stats BEFORE distribution
        const qfCUSDBalanceBefore = await CUSD_Deployer.balanceOf(QUADRATIC_FUNDING_ADDRESS);
        const qfNativeBalanceBefore = await ethers.provider.getBalance(QUADRATIC_FUNDING_ADDRESS); // Native balance
        const projectOwnerCUSDBalanceBefore = await CUSD_Deployer.balanceOf(projectOwnerAddress);
        const projectOwnerNativeBalanceBefore = await ethers.provider.getBalance(projectOwnerAddress);
        const projectStatsBefore = await quadraticFunding.getProjectStats(submittedProjectId);

        console.log(`QF Contract cUSD Balance: ${ethers.formatUnits(qfCUSDBalanceBefore, 18)}`);
        console.log(`QF Contract Native Balance (Matching Pool): ${ethers.formatEther(qfNativeBalanceBefore)}`);
        console.log(`Project Owner cUSD Balance: ${ethers.formatUnits(projectOwnerCUSDBalanceBefore, 18)}`);
        console.log(`Project Owner Native Balance: ${ethers.formatEther(projectOwnerNativeBalanceBefore)}`);
        console.log(`Project ${submittedProjectId} Total Contributions: ${ethers.formatUnits(projectStatsBefore.totalContributions, 18)} cUSD`);
        console.log(`Project ${submittedProjectId} Unique Contributors: ${projectStatsBefore.numUniqueContributors}`);
        console.log(`Project ${submittedProjectId} SumSqrtContributions (scaled): ${projectStatsBefore.sumSqrtContributions}`);


        // --- C. End Round & Distribute Funds ---
        console.log("\n--- C. Ending Round & Distributing Funds ---");

        console.log("Ending funding round...");
        const endRoundTx = await quadraticFunding.endRound();
        await endRoundTx.wait();
        console.log("Funding round ended! Tx Hash:", endRoundTx.hash);

        console.log("Distributing matching funds and direct contributions...");
        const distributeTx = await quadraticFunding.distributeMatchingFunds();
        await distributeTx.wait();
        console.log("Distribution successful! Tx Hash:", distributeTx.hash);


        // --- D. Post-Distribution State ---
        console.log("\n--- D. Post-Distribution State ---");

        // Query balances and stats AFTER distribution
        const qfCUSDBalanceAfter = await CUSD_Deployer.balanceOf(QUADRATIC_FUNDING_ADDRESS);
        const qfNativeBalanceAfter = await ethers.provider.getBalance(QUADRATIC_FUNDING_ADDRESS);
        const projectOwnerCUSDBalanceAfter = await CUSD_Deployer.balanceOf(projectOwnerAddress);
        const projectOwnerNativeBalanceAfter = await ethers.provider.getBalance(projectOwnerAddress);
        const projectStatsAfter = await quadraticFunding.getProjectStats(submittedProjectId); // Check if stats reset

        console.log(`QF Contract cUSD Balance: ${ethers.formatUnits(qfCUSDBalanceAfter, 18)}`);
        console.log(`QF Contract Native Balance (Matching Pool): ${ethers.formatEther(qfNativeBalanceAfter)}`);
        console.log(`Project Owner cUSD Balance: ${ethers.formatUnits(projectOwnerCUSDBalanceAfter, 18)}`);
        console.log(`Project Owner Native Balance: ${ethers.formatEther(projectOwnerNativeBalanceAfter)}`);
        console.log(`Project ${submittedProjectId} Total Contributions (should be 0 if reset): ${ethers.formatUnits(projectStatsAfter.totalContributions, 18)} cUSD`);
        console.log(`Project ${submittedProjectId} Unique Contributors (should be 0 if reset): ${projectStatsAfter.numUniqueContributors}`);

        // Verify the increase in project owner's balance
        const cUSDIncrease = projectOwnerCUSDBalanceAfter - projectOwnerCUSDBalanceBefore;
        const nativeIncrease = projectOwnerNativeBalanceAfter - projectOwnerNativeBalanceBefore;
        console.log(`Project Owner cUSD Increase: ${ethers.formatUnits(cUSDIncrease, 18)}`);
        console.log(`Project Owner Native Increase: ${ethers.formatEther(nativeIncrease)}`);


    } catch (error) {
        console.error("Error in QuadraticFunding interaction:", error.message);
        console.error("Please ensure you have Mock cUSD contract deployed and correctly configured.");
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
