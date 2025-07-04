# TukoPamoja-QF-KE

"Despite a vibrant and rapidly growing creative economy, Kenyan artists and content creators face significant barriers to sustainable income, fair compensation, and equitable access to funding. Centralized platforms often impose high fees and opaque policies, while traditional grant systems are bureaucratic and prone to bias. Furthermore, the lack of verifiable digital identities and community-driven funding mechanisms hinders grassroots projects and makes it difficult for creators to build trust and monetize their authentic work directly from their audience. This project aims to address these challenges by creating a decentralized quadratic funding protocol specifically designed to empower Kenyan creators."

Tuko Pamoja addresses several inefficiencies and challenges inherent in traditional funding models and community-driven initiatives, particularly within the context of Web3:
Inefficient Traditional Funding & Centralized Gatekeepers
Lack of Transparency in Fund Allocation
Difficulty in Coordinating & Verifying Community-Driven Projects
Limited User Control & Censorship Risk

#Architecture: Smart Contracts
The Tuko Pamoja DApp is built with a clear separation between its decentralized backend (smart contracts on the Celo blockchain) and its decentralized frontend (a React application hosted on IPFS).

#ProjectRegistry:
Purpose: The central repository for all registered projects. It stores essential metadata for each project, including its name, owner, category, a CID (Content Identifier) pointing to its detailed description on IPFS, and CIDs for associated image and audio files.
Key Functionality: Allows users (who meet specific criteria, e.g., holding an 'Artist' attestation) to register new projects and provides functions to retrieve project details and lists of projects by owner.

#AttestationService:
Purpose: Manages on-chain reputation and identity. It allows designated "Attestors" to issue various types of attestations (e.g., "Artist", "Verified Builder") to specific wallet addresses.
Key Functionality:The contract owner can add or remove attestors.
Attestors can issueAttestation to any recipient address for a given attestation type.
Provides a way to query if an address holds a specific attestation. This is crucial for access control, as seen with project submission.

#MockERC20 (mCUSD):
Purpose: A simple ERC-20 token contract that simulates a stablecoin on the Celo network (like CUSD). It's used as the currency for project contributions within the DApp.
Key Functionality: Standard ERC-20 functions like transfer, balanceOf, approve, and allowance.

#QuadraticFunding:
Purpose: Implements the core quadratic funding logic. It receives contributions in mCUSD from users, calculates matching funds based on the square root of contributions (promoting broader participation over large individual donations), and allows project owners to withdraw their accumulated funds.
Key Functionality:
contribute: Allows users to contribute mCUSD to a specific project.
getProjectStats: Retrieves real-time contribution statistics for a project.
getAvailableMatchingFunds: Calculates and returns the matching funds a project is eligible to receive.
withdrawMatchingFunds: Enables project owners to withdraw their collected contributions and matching funds.
