// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPool {
   function getDepositOrder(uint256 _nonce) external view returns(bytes32[2] memory);
   function setDataFromTransferReceiver(bytes memory data) external;
   function dataValidAndWithdrawalValidVerify(bytes memory _data) external view returns(bool, bool, address, uint48, bytes32);
   function setDataFromWithdrawSender(bytes32 privateKeyRelatedHash) external;

}




