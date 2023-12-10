// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IGetRelatedAddress.sol";

contract GetRelatedAddress is IGetRelatedAddress {

   
    address internal constant FactoryEthereum = 0xd7Ca4e99F7C171B9ea2De80d3363c47009afaC5F;
    bytes32 internal constant Pool_Ethereum_CODE_HASH = 0x2af2e46ac028226b80838a07d8537b684bddc5106d22c895646854f589064b99;
    bytes32 internal constant TransferSender_CODE_HASH = 0x4a23650f9f0e07bc0a19c8b3f75cca721b9f4b9cd276b73f6224261248a66ec9;
    bytes32 internal constant WithdrawReceiver_CODE_ARG_HASH = 0xb3d35634e382cecaa2c5a0319180bd8f5917e5d727a02e9918041f47e0c8bbde;

    address internal constant FactoryPolygon = 0x5e17b14ADd6c386305A32928F985b29bbA34Eff5;
    bytes32 internal constant Pool_Polygon_CODE_HASH = 0xed2dee2e87ddb471d2f26f8f7d43dd40725a1a04fde3000db2d36f50159e39ea;
    bytes32 internal constant WithdrawSender_CODE_HASH = 0xa1070174e1e278d3d3de8f057f0c9de9acd6d1558145949ae1971fa04abd7443;
    bytes32 internal constant TransferReceiver_CODE_ARG_HASH = 0xbb291a5ca298685a616b479c86c5c5ed7dfa88b70de2168185ba6c65fa5f19a8;
    


    constructor() {

    }

    function computeRelatedAddress(
        uint256 _depositAmount
        ) public view returns(
        address _pool,
        address _transferSender,
        address _withdrawReceiver,
        address _withdrawSender,
        address _transferReceiver
    ){

        require(msg.sender == FactoryEthereum || msg.sender == FactoryPolygon, "factory is not corret");

       
        bytes32 salt = keccak256(abi.encode(_depositAmount));

        if(msg.sender == FactoryEthereum) _pool = addressCreate2(msg.sender, salt, Pool_Ethereum_CODE_HASH);
        if(msg.sender == FactoryPolygon) _pool = addressCreate2(msg.sender, salt, Pool_Polygon_CODE_HASH);

        _transferSender = addressCreate2(FactoryEthereum, salt, TransferSender_CODE_HASH);
        _withdrawReceiver = addressCreate2(FactoryEthereum, salt, WithdrawReceiver_CODE_ARG_HASH);

        _withdrawSender = addressCreate2(FactoryPolygon, salt, WithdrawSender_CODE_HASH);
        _transferReceiver = addressCreate2(FactoryPolygon, salt, TransferReceiver_CODE_ARG_HASH);

    }

    function addressCreate2(address factory, bytes32 salt, bytes32 bytescodeArgHash) public pure returns (
        address _address
        ) {
        bytes memory data;
        data = abi.encodePacked(
                    hex'ff', 
                    factory, 
                    salt,  
                    bytescodeArgHash  
                );
        bytes32 _hashData = keccak256(data);
        _address = address(uint160(uint256(_hashData)));  
        
    }

    function getFactoryAddress() public pure returns(
        address _FactoryEthereum,
        address _FactoryPolygon
    ){
        _FactoryEthereum = FactoryEthereum;
        _FactoryPolygon = FactoryPolygon;
    }

}





