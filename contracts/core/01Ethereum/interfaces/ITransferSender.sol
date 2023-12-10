// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITransferSender {
    function sendMessagePayNative(uint256 _nonce) external payable returns (bytes32 messageId, uint256 fees);
    function sendMessagePayLink(uint256 _nonce) external payable returns (bytes32 messageId, uint256 fees);
}
