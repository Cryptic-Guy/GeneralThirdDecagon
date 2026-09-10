// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {IPoolManager, ModifyLiquidityParams} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {TimeGatedHook} from "../src/TimeGatedHook.sol";

contract TimeGatedHookTest is Test, Deployers {
    TimeGatedHook hook;
    uint256 openTime;
    uint256 closeTime;

    function setUp() public {
        deployFreshManagerAndRouters();
        (currency0, currency1) = deployMintAndApprove2Currencies();

        openTime = block.timestamp + 100;
        closeTime = block.timestamp + 1000;

        // Deploy code directly to flag address for testing
        address hookAddress = address(uint160(Hooks.BEFORE_SWAP_FLAG));
        deployCodeTo(
            "TimeGatedHook.sol:TimeGatedHook",
            abi.encode(manager, openTime, closeTime),
            hookAddress
        );
        hook = TimeGatedHook(hookAddress);

        (key, ) = initPool(currency0, currency1, hook, 3000, SQRT_PRICE_1_1);

        // Seed pool liquidity
        modifyLiquidityRouter.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: 10 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );
    }

    function test_RevertWhenBeforeOpenTime() public {
        vm.expectRevert();
        swap(key, true, -0.1 ether, ZERO_BYTES);
    }

    function test_SwapSucceedsDuringMarketHours() public {
        vm.warp(openTime + 50); // Jump forward into open trading hours
        swap(key, true, -0.1 ether, ZERO_BYTES);
    }

    function test_RevertWhenAfterCloseTime() public {
        vm.warp(closeTime + 10); // Jump forward past closing hours
        vm.expectRevert();
        swap(key, true, -0.1 ether, ZERO_BYTES);
    }

    function test_DemoTimeGatedHookFlow() public {
        console.log("==========================================");
        console.log("      TIME-GATED HOOK DEMO RUNNER         ");
        console.log("==========================================");
        console.log("Start Block Timestamp :", block.timestamp);
        console.log("Market Opening Time   :", openTime);
        console.log("Market Closing Time   :", closeTime);
        console.log("------------------------------------------");

        // Step 1: Swap Before Open Time
        console.log("\n[SCENARIO 1] Swapping BEFORE market opens...");
        vm.expectRevert();
        swap(key, true, -0.1 ether, ZERO_BYTES);
        console.log("[PASS] Swap reverted with TradingNotAllowed()");

        // Step 2: Swap During Open Hours
        vm.warp(openTime + 50);
        console.log("\n[SCENARIO 2] Warping timestamp to open hours:", block.timestamp);
        console.log("Attempting swap during open market hours...");
        swap(key, true, -0.1 ether, ZERO_BYTES);
        console.log("[PASS] Swap executed successfully!");

        // Step 3: Swap After Close Time
        vm.warp(closeTime + 100);
        console.log("\n[SCENARIO 3] Warping timestamp past close hours:", block.timestamp);
        console.log("Attempting swap after market close...");
        vm.expectRevert();
        swap(key, true, -0.1 ether, ZERO_BYTES);
        console.log("[PASS] Swap reverted with TradingNotAllowed()");
        console.log("==========================================");
    }
}