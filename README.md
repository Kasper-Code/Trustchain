# 🛡️ Trustchain

**Trustchain** is a decentralized digital legacy management system built on the Ethereum blockchain.  
It ensures that your digital assets and inheritance can be securely transferred to designated heirs if you become inactive for a specified period of time.

---

## 🧩 Project Description

In today’s digital world, managing what happens to your online assets after death or long inactivity is a real concern.  
**Trustchain** provides an on-chain solution that automates this process using smart contracts.  

The contract allows an owner to:
- Register heirs and assign each a percentage of their estate.
- Periodically send a “heartbeat” to signal activity.
- Automatically release the assets to heirs if the owner remains inactive for a defined period.

This eliminates reliance on centralized entities and ensures **transparency, immutability, and trustless execution**.

---

## ⚙️ What It Does

1. **Owner Setup**  
   The contract creator becomes the owner and sets an inactivity period (e.g., 30 days).

2. **Heir Registration**  
   The owner adds heirs with specific percentage shares of the estate.

3. **Heartbeat Updates**  
   The owner periodically calls the `heartbeat()` function to prove they are still active.

4. **Inactivity Trigger**  
   If the owner stops sending heartbeats for longer than the inactivity period, anyone can trigger the `releaseLegacy()` function.

5. **Fund Distribution**  
   ETH stored in the contract is automatically distributed among the heirs based on their assigned shares.

---

## ✨ Features

- ✅ **Decentralized Ownership** — no third-party control or access.  
- 🔐 **Secure Heir Management** — assign and update heirs with custom share percentages.  
- ⏱️ **Inactivity Detection** — triggers inheritance release after a set time of inactivity.  
- 💸 **Automatic Asset Distribution** — ETH (and optionally ERC20 tokens) are sent to heirs directly.  
- 📜 **Transparent & Verifiable** — every action is recorded immutably on-chain.  

---

## 🚀 Deployed Smart Contract

**Network:** (e.g. Sepolia / Polygon / Celo / Local VM)  
**Contract Address:** `XXX`

*(Replace `XXX` with your actual deployed contract address once you deploy it.)*

---

## 🧠 How to Use in Remix

1. Open [Remix IDE](https://remix.ethereum.org/).  
2. Load `Trustchain.sol` in the file explorer.  
3. Compile using Solidity `0.8.17` or higher.  
4. Deploy using:
   - **Environment:** Remix VM / Injected Provider (MetaMask)
   - **Constructor Parameter:** `_inactivityPeriod` in seconds (e.g., `86400` for 1 day).
5. Use the deployed contract functions:
   - `addHeir(address, share)`
   - `heartbeat()`
   - `releaseLegacy()`

---

## 🧾 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 💡 Future Enhancements

- Integration with ENS for easier heir identification.  
- Multi-token (ERC20/ERC721) support.  
- Off-chain proof-of-life or oracle-based verification system.  
- Web-based dApp interface for managing assets visually.

---

**Author:** [Srijan Paul  
**Project Name:** Trustchain  
**Tagline:** *Decentralized Digital Legacy Management for a Trustless Future*
