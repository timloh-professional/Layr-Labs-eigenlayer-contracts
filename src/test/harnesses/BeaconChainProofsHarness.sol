// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "../../contracts/libraries/BeaconChainProofs.sol";

contract BeaconChainProofsHarness {
    function verifyValidatorFields(
        uint40 validatorIndex,
        bytes32 beaconStateRoot,
        bytes calldata proof, 
        bytes32[] calldata validatorFields) external view {        
            BeaconChainProofs.verifyValidatorFields(
                validatorIndex,
                beaconStateRoot,
                proof, 
                validatorFields
            );
        }   
}