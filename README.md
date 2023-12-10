# Introduction
RingSig is a decentralized, regulated privacy solution based on Ethereum. 
We use the ring signature proof to enhance privacy when withdrawals cryptos from any address, 
which is so far unique in the market. We are fast, simple and secure.

# Chainlink usage
Our protocol uses Chainlink’s techniques in 3 places:  
1. **deposit on Supervisor.sol**: Chainlink.functions  
[FunctionsConsumer.sol](./contracts/supervisor/FunctionsConsumer.sol)  
[Piece of code that fulfillRequest on Supervisor.sol(line 89)](./contracts/supervisor/Supervisor.sol)
```
    function fulfillRequest(bytes memory response) public{
        require(response.length > 126, "response length is not correct"); 
        require(msg.sender == functionConsumer, "only functionConsumer");

       
        bytes memory _decodeBytesAddress = decodeToBytesFromEncodeString(slice(response, 0, 126));

        address _address1 = toAddress(_decodeBytesAddress, 0);
        address _address2 = toAddress(_decodeBytesAddress, 20);
        

        if(blacklist[_address1]==true && blacklist[_address2]==false) blacklist[_address2] = true;
        if(blacklist[_address2]==true && blacklist[_address1]==false) blacklist[_address1] = true;

        // send reward
        // to be done later...
    }

```

2. **transfer on main network Pool.sol**: Chainlink.CCIP synchronizes the information to L2  
[TransferSender.sol](./contracts/core/01Ethereum/TransferSender.sol)  
[TransferReceiver.sol](./contracts/core/02Polygon/TransferReceiver.sol)  
[Piece of code that set data on L2 Pool.sol(line 188)](./contracts/core/02Polygon/Pool.sol)
```
    function setDataFromTransferReceiver(bytes memory data) external {
        require(msg.sender == ccipReceiver, "only accept ccipReceiver");
        (uint256 _nonce, bytes32[2] memory publicKey) = abi.decode(data, (uint256, bytes32[2]));
       
        if(depositOrderOf[_nonce][0] == bytes32(0x0)){
            depositOrderOf[_nonce] = publicKey;
            if(_nonce > nonces) nonces = _nonce;
        }
    }
```


3. **withdraw on L2 Pool.sol**: Chainlink.CCIP synchronizes the information to main network and withdrawal operation is automatically executed on main network.  
[WithdrawSender.sol](./contracts/core/02Polygon/WithdrawSender.sol)  
[WithdrawReceiver.sol](./contracts/core/01Ethereum/WithdrawReceiver.sol)  
[Piece of code that withdraw on main network Pool.sol(line 267)](./contracts/core/01Ethereum/Pool.sol)

```
    function withdrawFromWithdrawReceiver(bytes memory data) external {
        require(msg.sender == ccipReceiver, "only for ccipReceiver");
        (
            address address_to,
            address withdrawer,
            uint48 fee,
            bytes32 privateKeyRelatedHash
        ) = abi.decode(data, (address, address, uint48, bytes32));

        require(withdrawDoneCheck[privateKeyRelatedHash] == false, "This privateKey already withdraw!");

        _witdraw(address_to, withdrawer, fee, privateKeyRelatedHash);
    }
```


