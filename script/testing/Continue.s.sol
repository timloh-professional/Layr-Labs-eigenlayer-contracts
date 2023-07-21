// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "./DeployOpenEigenLayer.s.sol";

// # To load the variables in the .env file
// source .env

// # To deploy and verify our contract
// forge script script/M1_Deploy.s.sol:Deployer_M1 --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast -vvvv
contract GenericDelegationTraffic is DeployOpenEigenLayer {
    string deployConfigPath = "script/testing/config.json";

    // deploy all the EigenDA contracts. Relies on many EL contracts having already been deployed.
    function run() external {
        // READ JSON CONFIG DATA
        string memory config_data = vm.readFile(deployConfigPath);
        uint256 numStrategies = stdJson.readUint(config_data, ".numStrategies");

        // _deployEigenLayer(msg.sender, msg.sender, msg.sender, strategyConfigs);

        // vm.stopBroadcast();

        uint256[] memory stakerPrivateKeys = stdJson.readUintArray(config_data, ".stakerPrivateKeys");
        address[] memory stakers = new address[](stakerPrivateKeys.length);
        for (uint i = 0; i < stakers.length; i++) {
            stakers[i] = vm.addr(stakerPrivateKeys[i]);
        }
        uint256[] memory stakerETHAmounts = new uint256[](stakers.length);
        // 0.1 eth each
        for (uint i = 0; i < stakerETHAmounts.length; i++) {
            stakerETHAmounts[i] = 0.1 ether;
        }

        // stakerTokenAmount[i][j] is the amount of token i that staker j will receive
        bytes memory stakerTokenAmountsRaw = stdJson.parseRaw(config_data, ".stakerTokenAmounts");
        uint256[][] memory stakerTokenAmounts = abi.decode(stakerTokenAmountsRaw, (uint256[][]));

        uint256[] memory operatorPrivateKeys = stdJson.readUintArray(config_data, ".operatorPrivateKeys");
        address[] memory operators = new address[](operatorPrivateKeys.length);
        for (uint i = 0; i < operators.length; i++) {
            operators[i] = vm.addr(operatorPrivateKeys[i]);
        }
        uint256[] memory operatorETHAmounts = new uint256[](operators.length);
        // 5 eth each
        for (uint i = 0; i < operatorETHAmounts.length; i++) {
            operatorETHAmounts[i] = 0.1 ether;
        }

        deployedStrategyArray.push(StrategyBaseTVLLimits(0xfc865ba4C9667Dd908771C0b93B54Cd38504DB2B));
        deployedStrategyArray.push(StrategyBaseTVLLimits(0x3E7607f9a791c41744a5c5124bcA504CB5915815));
        delegation = DelegationManager(0xc8dc37d6a0bABe0A4b8D298676Fbf9fc03039dE3);
        strategyManager = StrategyManager(0xEC3422B0B0583A4b9d12b72DA2d7BE294bc769f9);

        // Deposit stakers into EigenLayer and delegate to operators
        for (uint256 i = 3; i < stakerPrivateKeys.length; i++) {
            vm.startBroadcast(stakerPrivateKeys[i]);
            // for (uint j = 0; j < numStrategies; j++) {
            //     if(stakerTokenAmounts[j][i] > 0) {
            //         deployedStrategyArray[j].underlyingToken().approve(address(strategyManager), stakerTokenAmounts[j][i]);
            //         strategyManager.depositIntoStrategy(
            //             deployedStrategyArray[j],
            //             deployedStrategyArray[j].underlyingToken(),
            //             stakerTokenAmounts[j][i]
            //         );
            //     }
            // }
            IDelegationManager.SignatureWithExpiry memory approverSignatureAndExpiry;
            delegation.delegateTo(operators[i], approverSignatureAndExpiry);
            vm.stopBroadcast();
        }
    }

    function _allocate(IERC20 token, address[] memory tos, uint256[] memory amounts) internal {
        for (uint256 i = 0; i < tos.length; i++) {
            if(token == IERC20(address(0))) {
                payable(tos[i]).transfer(amounts[i]);
            } else {
                token.transfer(tos[i], amounts[i]);
            }
        }
    }
}