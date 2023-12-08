// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/IPool.sol";


/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A simple contract for receiving string data across chains.
contract WithdrawReceiver is CCIPReceiver {
    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        // string text // The text that was received.
        bytes data
    );

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    string private s_lastReceivedText; // Store the last received text.

    address public pool;
    address public sender;  // only accept sender

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router) CCIPReceiver(router) {
        (pool, sender) = IFactory(msg.sender).parametersForReceiver();
        
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {

        address _senderFromData = abi.decode(any2EvmMessage.sender, (address)); // abi-decoding of the sender address,
        require(_senderFromData == sender, "only accept sender from Polygon chain");
        
        (bool success, bytes memory data) = pool.call(any2EvmMessage.data);
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "withdrawFromWithdrawReceiver Failed"
        );

        // s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId
        // s_lastReceivedText = abi.decode(any2EvmMessage.data, (string)); // abi-decoding of the sent text

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            _senderFromData, // abi-decoding of the sender address,
            // abi.decode(any2EvmMessage.data, (string))
            any2EvmMessage.data
        );
    }

}
