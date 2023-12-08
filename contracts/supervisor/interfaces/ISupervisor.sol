// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISupervisor {
    // event Deposit(uint256 indexed index, uint256 amount, uint256 timestamp, address indexed depositor);

    function deposit() external payable;
    function report(address _blackAddress) external;
    function withdraw(uint256 index, uint256 _amount) external;
    function transfer(uint256 index, uint256 _amount) external;
    function fulfillRequest(bytes memory response) external;
    function getBlacklist(address _address) external view returns(bool);
    function getWhitelist(address _address) external view returns(bool);
}
