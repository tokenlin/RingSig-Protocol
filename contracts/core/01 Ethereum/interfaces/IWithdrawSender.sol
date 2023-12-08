// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWithdrawSender {
   function sendMessagePayNative(bytes memory _data, bool withdrawalValidCheck) external payable returns (
    bytes32 messageId,
    uint256 fees
    );
}
