// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/ISupervisor.sol";
import "./library/DecodeToBytes.sol";

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";



/**
 * @title Chainlink Functions example on-demand consumer contract example
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
  using FunctionsRequest for FunctionsRequest.Request;

  bytes32 public donId; // DON ID for the Functions DON to which the requests are sent

  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  bool public s_result;

  address public supervisor;
  // address public ownerOrignal;

  bytes32 public sourceHash = 0x01f17de6b636b6020dad082d4186941e9650c7368f0e67c91399935d35f78e76;

  constructor(address router, address _supervisor) FunctionsClient(router) ConfirmedOwner(msg.sender) {
    
    // ethereum-sepolia
    // address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 _donId = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;  // fun-ethereum-sepolia-1

    donId = _donId;
    supervisor = _supervisor;
    // ownerOrignal = _owner;
  }

  function changeSourceHash(bytes32 _hash) public onlyOwner{
    // require(msg.sender == owner, "only ownerOrignal");
    sourceHash = _hash;
  }

  function changeSupervisor(address _new) public onlyOwner{
    supervisor = _new;
  }

  /**
   * @notice Set the DON ID
   * @param newDonId New DON ID
   */
  function setDonId(bytes32 newDonId) external onlyOwner {
    donId = newDonId;
  }

  /**
   * @notice Triggers an on-demand Functions request using remote encrypted secrets
   * @param source JavaScript source code
   * secretsLocation Location of secrets (only Location.Remote & Location.DONHosted are supported)
   * encryptedSecretsReference Reference pointing to encrypted secrets
   * @param args String arguments passed into the source code and accessible via the global variable `args`
   * @param bytesArgs Bytes arguments passed into the source code and accessible via the global variable `bytesArgs` as hex strings
   * @param subscriptionId Subscription ID used to pay for request (FunctionsConsumer contract address must first be added to the subscription)
   * @param callbackGasLimit Maximum amount of gas used to call the inherited `handleOracleFulfillment` method
   */
  function sendRequest(
    string calldata source,
    // FunctionsRequest.Location secretsLocation,
    // bytes calldata encryptedSecretsReference,
    string[] calldata args,
    bytes[] calldata bytesArgs,
    uint64 subscriptionId,
    uint32 callbackGasLimit
  ) external returns(bytes32 RequestId){

    // check input args
    require(sourceHash == getSourceHash(source), "source incorrect");
    address[] memory addressList = DecodeToBytes.splitStringToAddressArray(args[1], ";");  // 
    require(ISupervisor(supervisor).getBlacklist(addressList[0]) == true || 
            ISupervisor(supervisor).getBlacklist(addressList[addressList.length-1]) == true, "no blacklist input");
    
    for(uint256 i=0; i<addressList.length; i++){
      require(ISupervisor(supervisor).getWhitelist(addressList[i]) == false, "no whitelist require");
    }


    FunctionsRequest.Request memory req; // Struct API reference: https://docs.chain.link/chainlink-functions/api-reference/functions-request
    req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source);
    // req.secretsLocation = secretsLocation;
    // req.encryptedSecretsReference = encryptedSecretsReference;
    if (args.length > 0) {
      req.setArgs(args);
    }
    if (bytesArgs.length > 0) {
      req.setBytesArgs(bytesArgs);
    }
    RequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, donId);
  }

  /**
   * @notice Store latest result/error
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    // s_lastRequestId = requestId;
    // s_lastResponse = response;
    // s_lastError = err;
    
    // due to max gas 300_000
    if(response.length > 0){
      bytes memory functionCallData = abi.encodeWithSignature("fulfillRequest(bytes)", response);
      supervisor.call(functionCallData);
      // (bool success, ) = supervisor.call(functionCallData);
      // s_result = success;
    }
  }

  function getSourceHash(string memory source) public pure returns(bytes32){
    return keccak256(abi.encodePacked(source));
  }
}