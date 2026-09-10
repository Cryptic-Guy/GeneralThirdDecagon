# ⏳ TimeGatedHook | Uniswap v4

A custom **Uniswap v4 Hook** that restricts pool trading activity to a specific time window. Any swap attempted outside the configured opening and closing timestamps is automatically blocked and reverts with `TradingNotAllowed()`.

Ideal for token launches, scheduled trading hours, or programmatic liquidity gating.

---

## 📑 Overview

The `TimeGatedHook` leverages the `beforeSwap` lifecycle hook from Uniswap v4. Before any swap execution, the hook validates the current `block.timestamp` against the configured window:

- **`startTimestamp`**: Unix timestamp when trading opens.
- **`endTimestamp`**: Unix timestamp when trading closes.

If `block.timestamp < startTimestamp` or `block.timestamp > endTimestamp`, the swap reverts before pool balances or state are modified.

---

## 🛠 Hook Permissions

| Permission | Enabled | Description |
| :--- | :---: | :--- |
| `beforeSwap` | ✅ | Validates `block.timestamp` against trading window |
| `afterSwap` | ❌ | Disabled |
| `beforeInitialize` / `afterInitialize` | ❌ | Disabled |
| `beforeAddLiquidity` / `afterAddLiquidity` | ❌ | Disabled |
| `beforeRemoveLiquidity` / `afterRemoveLiquidity` | ❌ | Disabled |

---

## 🚀 Quickstart

### Prerequisites

Ensure you have **Foundry** installed:

```bash
curl -L [https://foundry.paradigm.xyz](https://foundry.paradigm.xyz) | bash
foundryup

### Installation & Compilation

```bash
# Install dependencies
forge install

# Build contracts
forge build

## 🧪 Testing

Run the full unit test suite:

```bash
forge test

### Interactive Console Demo

Run the scenario runner to observe pre-market, active market, and post-market hook responses:

```bash
forge test --match-test test_DemoTimeGatedHookFlow -vv

#### Output Log Example:

```text
==========================================
      TIME-GATED HOOK DEMO RUNNER         
==========================================
Start Block Timestamp : 1
Market Opening Time   : 101
Market Closing Time   : 1001
------------------------------------------

[SCENARIO 1] Swapping BEFORE market opens...
[PASS] Swap reverted with TradingNotAllowed()

[SCENARIO 2] Warping timestamp to open hours: 151
Attempting swap during open market hours...
[PASS] Swap executed successfully!

[SCENARIO 3] Warping timestamp past close hours: 1101
Attempting swap after market close...
[PASS] Swap reverted with TradingNotAllowed()
==========================================

## 📦 Deployment

Uniswap v4 requires hook deployment addresses to match specific flag bits. The deployment script uses CREATE2 salt mining to locate a valid `BEFORE_SWAP_FLAG` address.

### 1. Simulation (Dry-Run)

```bash
forge script script/DeployHook.s.sol:DeployHook -vvvv

### 2. Live Network Broadcast

```bash
PRIVATE_KEY=0xYourPrivateKey forge script script/DeployHook.s.sol:DeployHook \
  --rpc-url <RPC_URL> \
  --broadcast \
  -vvvv

  ## 📄 License

  Distributed under the MIT License.