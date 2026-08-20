# AFX Hook - Dynamic Fees for African Stablecoins on Base

> Uniswap v4 hook that protects LPs and rewards traders on volatile African stablecoin pairs (cNGN, cKES, cGHS) - Built for Base

[![Base](https://img.shields.io/badge/Built%20for-Base-blue?logo=coinbase)](https://base.org)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-black)](https://soliditylang.org)
[![Uniswap v4](https://img.shields.io/badge/Uniswap-v4-pink)](https://docs.uniswap.org)

### Applied to Base Ecosystem Fund - Aug 2025

**Live:** `github.com/ETK2456/afx-hook` | **Founder:** ETK2456 (Port Harcourt, NG)

## Problem
African stablecoins (cNGN) are 5-10x more volatile than USDC. Fixed 0.05% / 0.3% pools bleed LPs during spikes and overcharge traders when calm. Result: No liquidity for African pairs.

## Solution
Volatility-aware dynamic fee hook:

- `beforeSwap` calculates fee from TWAP volatility (Pyth / Chainlink on Base)
- Fees auto-adjust 0.01% - 1.5%
- Calm market: 0.05% (attract traders)
- Normal: 0.3%
- Volatile: 0.8% - 1.5% (protect LPs)

## Why Base?
- Uniswap v4 is live on Base
- Base gas < $0.01 perfect for Nigerian traders vs $1+ on mainnet
- Coinbase on-ramp for cNGN -> USDC
- Superchain compatible with Unichain

## Architecture
