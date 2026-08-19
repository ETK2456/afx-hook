# AFX Hook - Dynamic Fees for African Stablecoins

Uniswap v4 hook that protects LPs and rewards traders on volatile African stablecoin pairs (cNGN, cKES, GHST) on Unichain.

## Problem
African stablecoins (cNGN) are 5-10x more volatile than USDC. Fixed 0.05% / 0.3% pools bleed LPs during spikes and overcharge traders when calm. Result: No liquidity.

## Solution
Volatility-aware dynamic fee hook:
- `beforeSwap` calculates fee from TWAP volatility
- Fees auto-adjust 0.01% - 1.5%
- Calm market: 0.05% (attract traders)
- Normal: 0.3%
- Volatile: 0.8% - 1.5% (protect LPs)

## Architecture
