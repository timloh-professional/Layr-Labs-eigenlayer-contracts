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
        StrategyConfig[] memory strategyConfigs = new StrategyConfig[](numStrategies);

        // vm.startBroadcast(msg.sender);

        // deploy a token and create a strategy config for each token
        for (uint8 i = 0; i < numStrategies; i++) {
            address tokenAddress = address(new ERC20PresetFixedSupply(string(abi.encodePacked("Token", i)), string(abi.encodePacked("TOK", i)), 1000 ether, msg.sender));
            strategyConfigs[i] = StrategyConfig({
                maxDeposits: type(uint256).max,
                maxPerDeposit: type(uint256).max,
                tokenAddress: tokenAddress,
                tokenSymbol: string(abi.encodePacked("TOK", i))
            });
        }

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

        vm.startBroadcast();

        // Allocate eth to stakers and operators
        _allocate(
            IERC20(address(0)),
            stakers,
            stakerETHAmounts
        );

        _allocate(
            IERC20(address(0)),
            operators,
            operatorETHAmounts
        );

        // Allocate tokens to stakers
        for (uint8 i = 0; i < numStrategies; i++) {
            _allocate(
                IERC20(deployedStrategyArray[i].underlyingToken()),
                stakers,
                stakerTokenAmounts[i]
            );
        }

        {
            IStrategy[] memory strategies = new IStrategy[](numStrategies);
            for (uint8 i = 0; i < numStrategies; i++) {
                strategies[i] = deployedStrategyArray[i];
            }
            strategyManager.addStrategiesToDepositWhitelist(strategies);
        }

        vm.stopBroadcast();

        // Register operators with EigenLayer
        for (uint256 i = 0; i < operatorPrivateKeys.length; i++) {
            vm.broadcast(operatorPrivateKeys[i]);
            address earningsReceiver = address(uint160(uint256(keccak256(abi.encodePacked(operatorPrivateKeys[i])))));
            address delegationApprover = address(0); //address(uint160(uint256(keccak256(abi.encodePacked(earningsReceiver)))));
            uint32 stakerOptOutWindowBlocks = 100;
            string memory metadataURI = string(abi.encodePacked("https://urmom.com/operator/", i));
            delegation.registerAsOperator(IDelegationManager.OperatorDetails(earningsReceiver, delegationApprover, stakerOptOutWindowBlocks), metadataURI);
        }

        // Deposit stakers into EigenLayer and delegate to operators
        for (uint256 i = 0; i < stakerPrivateKeys.length; i++) {
            vm.startBroadcast(stakerPrivateKeys[i]);
            for (uint j = 0; j < numStrategies; j++) {
                if(stakerTokenAmounts[j][i] > 0) {
                    deployedStrategyArray[j].underlyingToken().approve(address(strategyManager), stakerTokenAmounts[j][i]);
                    strategyManager.depositIntoStrategy(
                        deployedStrategyArray[j],
                        deployedStrategyArray[j].underlyingToken(),
                        stakerTokenAmounts[j][i]
                    );
                }
            }
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