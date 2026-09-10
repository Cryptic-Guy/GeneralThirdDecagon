// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {TimeGatedHook} from "../src/TimeGatedHook.sol";

contract DeployHook is Script {
    // Official Sepolia PoolManager address
    address constant POOL_MANAGER = 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543;
    // Standard CREATE2 deployer address
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function run() external {
        uint256 openTime = block.timestamp + 1 hours;
        uint256 closeTime = block.timestamp + 1 days;

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(POOL_MANAGER, openTime, closeTime);

        // Mine salt to produce address matching BEFORE_SWAP_FLAG
        (address expectedAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(TimeGatedHook).creationCode,
            constructorArgs
        );

        vm.startBroadcast();
        TimeGatedHook hook = new TimeGatedHook{salt: salt}(
            IPoolManager(POOL_MANAGER),
            openTime,
            closeTime
        );
        require(address(hook) == expectedAddress, "Address mismatch");
        vm.stopBroadcast();

        console.log("Deployed TimeGatedHook to:", address(hook));
    }
}