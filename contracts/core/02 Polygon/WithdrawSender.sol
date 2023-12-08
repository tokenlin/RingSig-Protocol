// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import "./library/TransferHelper.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IWithdrawSender.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @title - A simple contract for sending string data across chains.
contract WithdrawSender is OwnerIsCreator, IWithdrawSender {
    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        // string text, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    IRouterClient private s_router;

    address public pool;
    address public router;
    address public receiver;
    uint64 public destinationChainSelector;

    LinkTokenInterface public s_linkToken;

    /// @notice Constructor initializes the contract with the router address.
    constructor() {
        address _link;
        (pool, router, receiver, _link, destinationChainSelector) = IFactory(msg.sender).parametersForSender();
        s_router = IRouterClient(router);
        s_linkToken = LinkTokenInterface(_link);
    }


    function sendMessagePayLink(
        bytes memory _data, 
        bool withdrawalValidCheck
    ) external payable returns (bytes32 messageId, uint256 fees) {

        bytes32 privateKeyRelatedHash;
        bytes memory functionCallData;
        Client.EVM2AnyMessage memory evm2AnyMessage;
        
        // data check and get functionCallData
        (privateKeyRelatedHash, , functionCallData) = dataCheckAndGetFunctionCallData(_data, withdrawalValidCheck);
       
        // get evm2AnyMessage and feesForDestinationChain
        (evm2AnyMessage, fees)= getEvm2AnyMessageAndFees(functionCallData, true);
       
        // setting on pool
        IPool(pool).setDataFromWithdrawSender(privateKeyRelatedHash);


        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);
        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        s_linkToken.approve(address(s_router), fees);

             
        // Send the message through the router and store the returned message ID
        messageId = s_router.ccipSend(destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            // text,
            address(s_linkToken),  // native ******************
            fees
        );
    }

    





    function sendMessagePayNative(
        bytes memory _data, 
        bool withdrawalValidCheck
    ) external payable returns(bytes32 messageId, uint256 fees){  // every one can call this function

        bytes32 privateKeyRelatedHash;
        bytes memory functionCallData;
        Client.EVM2AnyMessage memory evm2AnyMessage;
        
        // data check and get functionCallData
        (privateKeyRelatedHash, , functionCallData) = dataCheckAndGetFunctionCallData(_data, withdrawalValidCheck);
       
        // get evm2AnyMessage and feesForDestinationChain
        (evm2AnyMessage, fees)= getEvm2AnyMessageAndFees(functionCallData, false);
       
        // setting on pool
        IPool(pool).setDataFromWithdrawSender(privateKeyRelatedHash);

        // send
        // if (fees > address(this).balance)
        if (fees > msg.value)
            revert NotEnoughBalance(msg.value, fees);
        
        // 返回多余的主币给调用者
        if (msg.value > fees) TransferHelper.safeTransferETH(tx.origin, (msg.value - fees));
        
        // ****************************************
        // Send the message through the router and store the returned message ID
        messageId = s_router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            // text,
            address(0),  // native ******************
            fees
        );

    }




    function dataCheckAndGetFunctionCallData(
        bytes memory _data, 
        bool withdrawalValidCheck
    )public view returns(
        bytes32 privateKeyRelatedHash,
        bytes memory _arg,
        bytes memory functionCallData
    ){
        address withdrawer = tx.origin;

        bool withdrawalValid;
        bool dataValid;
        address address_to;
        uint48 fee;

        (
            withdrawalValid, 
            dataValid, 
            address_to, 
            fee, 
            privateKeyRelatedHash
        ) = IPool(pool).dataValidAndWithdrawalValidVerify(_data);

        if(withdrawalValidCheck == true) require(withdrawalValid == true, "This privateKey already withdraw!");
        require(dataValid == true, "Input data can not be verified");     

        _arg = abi.encode(address_to, withdrawer, fee, privateKeyRelatedHash);
        functionCallData = abi.encodeWithSignature("withdrawFromWithdrawReceiver(bytes)", _arg);

    }



    function getEvm2AnyMessageAndFees(
        bytes memory functionCallData, bool payLink
    ) public view returns(
        Client.EVM2AnyMessage memory evm2AnyMessage,
        uint256 fees
    ){
        evm2AnyMessage = getEvm2AnyMessage(functionCallData, payLink);

        fees = s_router.getFee(
            destinationChainSelector,
            evm2AnyMessage
        );
    }


    function getEvm2AnyMessage(bytes memory functionCallData, bool payLink) public view returns(
        Client.EVM2AnyMessage memory evm2AnyMessage
        ){

        address feeToken;
        if(payLink){
            feeToken = address(s_linkToken);
        }else{
            feeToken = address(0);
        }

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: functionCallData, // ABI-encoded bytes
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 800_000, strict: false})
            ),
            // Set the feeToken  address, indicating LINK will be used for fees
            feeToken: feeToken  // pay      *******************************
        });
    }

}
