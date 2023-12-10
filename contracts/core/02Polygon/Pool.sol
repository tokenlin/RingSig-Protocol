// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./library/Bytes32Lib.sol";
import "./library/BytesLib.sol";
import "./library/EllipticCurve.sol";
import "./library/TransferHelper.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/ISupervisor.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITransferSender.sol";
import "./interfaces/IWithdrawSender.sol";

contract Pool is IPool {
    using BytesLib for bytes;
    using EllipticCurve for bytes32[2];
    using Bytes32Lib for bytes32;

    event WithdrawLog(bytes32 indexed _hash, address indexed _to);

    bytes32 constant Gx = bytes32(uint256(1));
    bytes32 constant Gy = bytes32(uint256(2));

    bytes32 constant Hx = 0x06e120c2c3547c60ee47f712d32e5acf38b35d1cc62e23b055a69bb88284c282;
    bytes32 constant Hy = 0x16932a2d5a8000de7a60d3fa813123776d3b01d3b0e0c2ae8cf09303d04fc4d7;

    mapping(bytes32 => bool) public depositDoneCheck;  
    mapping(bytes32 => bool) public withdrawDoneCheck; 
    
    uint256 public nonces; 
    uint256 public numsWithdraw; 
    uint256 public nounceMixedBegin;
    mapping(uint256 => bytes32[2]) depositOrderOf; 

    uint256 public feeForOwner;

    uint256 public availableBalanceOfOwner; 

    uint256 public depositAmount;
    address public owner;
    address public supervision;
    address public ccipSender;
    address public ccipReceiver;

    constructor() {
        (depositAmount, owner, supervision, ccipSender, ccipReceiver) = IFactory(msg.sender).parametersForPool();
    }


    function withdrawByOwner(uint256 _amount) public {
        require(_amount <= availableBalanceOfOwner, "Withdraw amount shall be not more than available balance!");
        require(msg.sender == owner, "Only for owner!");
        TransferHelper.safeTransferETH(owner, _amount);
        availableBalanceOfOwner = availableBalanceOfOwner - _amount;
    }

    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "Only for owner!");
        owner = _newOwner;
    }

    function setFeeForOwner(uint256 _fee) public{
        require(msg.sender == owner, "Only for owner!");
        require(_fee <= 500, "feeForOwner should be not more than 500!");  // max 500 / 1000
        feeForOwner = _fee;
    }


    function withdrawOnPolygon(bytes memory _data, bool payLink) public payable{
        bool withdrawalValidCheck = true;
    
        if(payLink){
            IWithdrawSender(ccipSender).sendMessagePayLink(_data, withdrawalValidCheck);
        }else{
            IWithdrawSender(ccipSender).sendMessagePayNative{value: msg.value}(_data, withdrawalValidCheck); 
        }
    }

    
    function getReward(bytes memory _data) public view returns(uint256, uint256, uint256){
        uint48 fee;
        (, , , fee, ) = dataValidAndWithdrawalValidVerify(_data);
       
        uint256 fees = depositAmount * fee / 10**9;  
        uint256 amountForOwner = fees * feeForOwner / 1000;  
        uint256 amountForWithdrawer = fees - amountForOwner;  
        return (fees, amountForOwner, amountForWithdrawer);
    }

    
    function dataValidAndWithdrawalValidVerify(bytes memory _data) public view returns(bool, bool, address, uint48, bytes32){
        address address_to = _data.toAddress(0);
        uint48 fee = _data.toUint48(20);
        require(fee < 10**9, "fee should be less than 10**9!");
        
        bytes32[2] memory kH = [_data.toBytes32(32), _data.toBytes32(64)];

       
        bytes32 privateKeyRelatedHash;
        privateKeyRelatedHash = keccak256(abi.encodePacked(kH[0], kH[1]));
        bool withdrawalValid;
        if(withdrawDoneCheck[privateKeyRelatedHash] == false) withdrawalValid = true;       
        
        bool dataValid;
        dataValid = _dataVerify(_data);
        if(dataValid == true) dataValid = true;

        return (withdrawalValid, dataValid, address_to, fee, privateKeyRelatedHash);

    }

    function _dataVerify(bytes memory _data) private view returns(bool){
        uint256 len = (_data.length - 4 * 32)/32/2;
        bytes32 address_fee_len;
        bytes32[2] memory kH;
        bytes32 s;
        bytes32[] memory c_list = new bytes32[](len);
        bytes32[2][] memory public_keys_list = new bytes32[2][](len);

        require(len >= 3, "The number of Ring can not be less than 3!");

        (len, address_fee_len, kH, s, c_list, public_keys_list) = getParameter(_data);

        bytes32 c_cal;
        for(uint256 i=0; i<len; i++){
            c_cal = c_cal.addMod(c_list[i]);
        }


        bytes32[2] memory GH = [Gx, Gy].bn256Add([Hx, Hy]);
        bytes32[2] memory R = GH.bn256ScalarMul(s);
        for(uint256 i=0; i<len; i++){
            bytes32[2] memory cP = public_keys_list[i].bn256ScalarMul(c_list[i]);
            R = R.bn256Add(cP);
        }
        bytes32[2] memory ckH = kH.bn256ScalarMul(c_cal);
        R = R.bn256Add(ckH);

        bytes32 c = keccak256(abi.encodePacked(address_fee_len, kH[0], kH[1], R[0], R[1]));
        c = c.addMod(bytes32(uint256(0)));

        if (c == c_cal) return true;

        return false;
    }

   
    function getParameter(bytes memory _data) public view returns(
        uint256 len, 
        bytes32 address_fee_len,
        bytes32[2] memory kH,
        bytes32 s,
        bytes32[] memory c_list,
        bytes32[2][] memory public_keys_list
        ){
       
        len = (_data.length - 4 * 32)/32/2;

        
        address_fee_len = _data.toBytes32(0);  
       
        kH = [_data.toBytes32(32), _data.toBytes32(64)];  

        s = _data.toBytes32(96);

        c_list = new bytes32[](len);
        uint256 index = 128;
        for(uint256 i = 0; i < len; i++){
            c_list[i] = _data.toBytes32(index);
            index = index + 32;
        }

        public_keys_list = new bytes32[2][](len);
        for(uint256 i = 0; i < len; i++){
            uint256 sn = uint256(_data.toBytes32(index));  
            public_keys_list[i] = depositOrderOf[sn];  
            require(public_keys_list[i][0] != bytes32(0), "Invalid publicKey input!");
            index = index + 32;
        }
    }


    function getDepositOrder(uint256 _nonce) public view returns(bytes32[2] memory){
        return depositOrderOf[_nonce];
    }

    function setDataFromTransferReceiver(bytes memory data) external {
        require(msg.sender == ccipReceiver, "only accept ccipReceiver");
        (uint256 _nonce, bytes32[2] memory publicKey) = abi.decode(data, (uint256, bytes32[2]));
       
        if(depositOrderOf[_nonce][0] == bytes32(0x0)){
            depositOrderOf[_nonce] = publicKey;
            if(_nonce > nonces) nonces = _nonce;
        }
    }


    function setDataFromWithdrawSender(bytes32 privateKeyRelatedHash) external {
        require(msg.sender == ccipSender, "only accept ccipSender");
        withdrawDoneCheck[privateKeyRelatedHash] = true;
        numsWithdraw = numsWithdraw + 1; 
       
        if(numsWithdraw == nonces){
            nounceMixedBegin = nonces;
        }
    }

}




