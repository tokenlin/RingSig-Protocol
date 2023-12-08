// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPool {
   function getDepositOrder(uint256 _nonce) external view returns(bytes32[2] memory);
   function dataValidAndWithdrawalValidVerify(bytes memory _data) external view returns(bool, bool, address, uint48, bytes32);

}




