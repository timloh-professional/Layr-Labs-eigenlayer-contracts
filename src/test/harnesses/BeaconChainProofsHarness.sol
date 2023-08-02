// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "../../contracts/libraries/BeaconChainProofs.sol";

contract BeaconChainProofsHarness {
    function verifyValidatorFields(
        uint40 validatorIndex,
        bytes32 beaconStateRoot,
        bytes calldata proof, 
        bytes32[] calldata validatorFields) external view returns(bool) {        
            BeaconChainProofs.verifyValidatorFields(
                validatorIndex,
                beaconStateRoot,
                proof, 
                validatorFields
            );
            return true;
    } 

    function verifyValidatorBalance(
        uint40 validatorIndex,
        bytes32 beaconStateRoot,
        bytes calldata proof,
        bytes32 balanceRoot
    ) external view returns(bool) {
        BeaconChainProofs.verifyValidatorBalance(
            validatorIndex,
            beaconStateRoot,
            proof,
            balanceRoot
        );
        return true;
    }

    function verifySlotRoot(
        bytes32 beaconStateRoot,
        bytes calldata proof,
        bytes32 slotRoot
    ) external view returns(bool) {
        BeaconChainProofs.verifySlotRoot(
            beaconStateRoot,
            proof,
            slotRoot
        );
        return true;
    }

    function verifyStateRootAgainstLatestBlockHeaderRoot(
        bytes32 beaconStateRoot,
        bytes32 latestBlockHeaderRoot,
        bytes calldata proof
    ) external view returns(bool) {
        BeaconChainProofs.verifyStateRootAgainstLatestBlockHeaderRoot(
            beaconStateRoot,
            latestBlockHeaderRoot,
            proof
        );
        return true;
    }   
}