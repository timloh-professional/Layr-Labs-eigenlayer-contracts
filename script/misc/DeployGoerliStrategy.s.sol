// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../src/contracts/strategies/StrategyBaseTVLLimits.sol";
import "../../src/contracts/permissions/PauserRegistry.sol";


import "forge-std/Script.sol";
import "forge-std/Test.sol";

// # To load the variables in the .env file
// source .env

// # To deploy and verify our contract
// forge script script/misc/DeployStrategy.s.sol:DeployStrategy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv

// NOTE: ONLY WORKS ON GOERLI
contract DeployStrategy is Script, Test {
    Vm cheats = Vm(HEVM_ADDRESS);

    // EigenLayer Contracts
    ProxyAdmin public eigenLayerProxyAdmin = ProxyAdmin(0x78F5fb504a039Bc12e6C8AE0F33BE609648957cd);
    PauserRegistry public eigenLayerPauserReg = PauserRegistry(0x95e76e31FAAA973A5F1B9E1239210D52098566ca);
    StrategyBase public baseStrategyImplementation = StrategyBase(0x22e2baC8E504fBD6ccE7D834581947C8E38799a8);

    function run() external {
        // read and log the chainID
        uint256 chainId = block.chainid;
        emit log_named_uint("You are deploying on ChainID", chainId);

        address tokenAddress = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F;

        vm.startBroadcast();

        // create upgradeable proxies that each point to the implementation and initialize them
        address strategy = address(
                    new TransparentUpgradeableProxy(
                        address(baseStrategyImplementation),
                        address(eigenLayerProxyAdmin),
                        abi.encodeWithSelector(
                            StrategyBaseTVLLimits.initialize.selector, 
                            115792089237316195423570985008687907853269984665640564039457584007913129639935, 
                            115792089237316195423570985008687907853269984665640564039457584007913129639935, 
                            tokenAddress, 
                            eigenLayerPauserReg
                        )
                    )
                );

        vm.stopBroadcast();

        emit log_named_address("Strategy", strategy);

    }
}