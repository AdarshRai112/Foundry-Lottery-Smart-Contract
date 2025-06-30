# 🚀 Smart Contract Lottery

> A Solidity-powered lottery system where users enter by sending Ether, and Chainlink VRF selects a random winner to receive all collected funds.

---

## 📌 Table of Contents

- [About](#about)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Learnings](#learnings)
- [Project Structure](#project-structure)
- [Screenshots / Demo](#screenshots--demo)
- [Contributing](#contributing)
- [License](#license)

---

## 📖 About

> This is a decentralized lottery (raffle) smart contract built with Solidity and powered by Chainlink Automation. Participants can enter the lottery by sending a fixed amount of Ether as an entry fee. The contract automatically selects a random winner at regular intervals — but only if certain conditions are met (like having enough players, a positive balance, and an open raffle state).
---

## ✨ Features

- **💸 Ether-Based Entry**: Users participate in the lottery by sending a fixed amount of Ether to the contract.
- **🔁 Automated Winner Selection**: Uses Chainlink Automation to automatically trigger winner selection at regular time intervals.
- **✅ Conditional Execution**:
- **1**. Minimum one player required
- **2**. Contract must have a positive balance
- **3**. Raffle must be in `OPEN` state
- **4**. Time interval must be passed
- 🥇 **Winner Takes All**: The entire contract balance is sent to the randomly selected winner.
- 🔒 **Raffle State Control**: Prevents entries during winner selection using enum states (`OPEN`, `CALCULATING`).
- 🛠️ **Chainlink-Ready**: Integrates with Chainlink Automation

---

## 🧰 Tech Stack

- **Solidity** – Smart contract development  
- **Foundry** – Build, test, deploy smart contracts  
- **Chainlink** – VRF and Automation  
- **Sepolia testnt** – Metamask wallet  

---

## 🛠 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- [chainlink-brownie-contracts]
- Git

### Installation

```bash
git clone https://github.com/your-username/project-name.git
cd project-name
forge install
forge build
