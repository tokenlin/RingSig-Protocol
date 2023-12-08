// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISupervisor {
    function deposit() external payable;
    function report(address _blackAddress) external;
    function withdraw(uint256 index, uint256 _amount) external;
    function transfer(uint256 index, uint256 _amount) external;
}
