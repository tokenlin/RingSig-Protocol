// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IGetRelatedAddress.sol";

contract GetRelatedAddress is IGetRelatedAddress {

    
    address internal constant FactoryEthereum = 0x9C7F4a0145d8ccbd377B12D619996De90Bfd7023;
    bytes32 internal constant Pool_Ethereum_CODE_HASH = 0xc9753a223b49733241af6e2649da1bab7faa4aba80df41b01b8560fb3eb92105;
    bytes32 internal constant TransferSender_CODE_HASH = 0xc5c244f1260d96c6365dad4df2d54bccb7a5800de9a4903c77f2f7dc40a2ca3e;
    bytes32 internal constant WithdrawReceiver_CODE_ARG_HASH = 0xb48fda17f5b459029a2e43e0e28d766e1e66e985a12af90aa4c71e9916223d71;

    address internal constant FactoryPolygon = 0xefB54993d5574F955cce8C4B9d45E5e97FdcEf50;
    bytes32 internal constant Pool_Polygon_CODE_HASH = 0x08f0b14ebe1e987ee5554730bbdf06db43891a20317ab0a9bc18fc5571b1620b;
    bytes32 internal constant WithdrawSender_CODE_HASH = 0xa18aadc7268af6fbd0e9bb629a4d63f830a3f031d16924559ca0675f3c77c64f;
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





