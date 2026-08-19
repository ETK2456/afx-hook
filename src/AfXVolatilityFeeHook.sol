// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";

/// @title AFX Hook - Dynamic Fee Hook for African Stablecoins
/// @author ETK2456 - Built in Lagos
/// @notice Adjusts LP fees 0.01% - 1.5% based on volatility for cNGN, KES, GHS pairs
contract AfXVolatilityFeeHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using LPFeeLibrary for uint24;

    // Fees in hundredths of a bip (100 = 0.01%)
    uint24 public constant MIN_FEE = 100; // 0.01%
    uint24 public constant BASE_FEE = 3000; // 0.30%
    uint24 public constant MAX_FEE = 15000; // 1.50%

    mapping(PoolId => uint256) public lastUpdate;
    mapping(PoolId => uint24) public lastCalculatedFee;

    event FeeUpdated(PoolId indexed poolId, uint24 fee, uint256 timestamp);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Only pools that enable dynamic fees can use this hook
    function beforeInitialize(address, PoolKey calldata key, uint160)
        external
        pure
        override
        returns (bytes4)
    {
        if (!key.fee.isDynamicFee()) revert("AFX: dynamic fee required");
        return BaseHook.beforeInitialize.selector;
    }

    // Called before every swap - we set the fee here
    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        uint24 dynamicFee = _getDynamicFee(poolId);

        // Return fee with override flag so PoolManager uses our fee
        uint24 feeWithFlag = dynamicFee | LPFeeLibrary.OVERRIDE_FEE_FLAG;

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, feeWithFlag);
    }

    // Called after swap - update timestamp for volatility calc
    function afterSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4, int128) {
        PoolId poolId = key.toId();
        lastUpdate[poolId] = block.timestamp;
        return (BaseHook.afterSwap.selector, 0);
    }

    // Core logic - MVP uses time since last swap as volatility proxy
    // Production: replace with Chainlink cNGN/USD + Uniswap TWAP std dev
    function _getDynamicFee(PoolId poolId) internal view returns (uint24) {
        uint256 last = lastUpdate[poolId];

        if (last == 0) {
            return BASE_FEE; // first swap
        }

        uint256 timeSince = block.timestamp - last;

        if (timeSince < 1 minutes) {
            return 8000; // 0.8% - high volatility / high activity
        } else if (timeSince < 10 minutes) {
            return BASE_FEE; // 0.3% - normal
        } else {
            return 500; // 0.05% - calm, attract traders
        }
    }

    // For testing on Sepolia
    function setMockLastUpdate(PoolId poolId, uint256 timestamp) external {
        lastUpdate[poolId] = timestamp;
    }
}
