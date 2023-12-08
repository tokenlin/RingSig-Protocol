// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./BytesLib.sol";

library DecodeToBytes{

    // ";" => 0x3b (ascii 59)
    // "0" => 0x30 (ascii 48)
    // "9" => 0x39 (ascii 57)

    // "A" => (ascii 65)
    // "F" => (ascii 70)
    // "X" => (ascii 88)

    // "a" => (ascii 97)
    // "f" => (ascii 102)
    // "x" => (ascii 120)

    // encode from string "0xadb...09", decode to bytes 0xadb...09 
    function decodeToBytesFromEncodeString(bytes memory _b) public pure returns(
        bytes memory
        // uint256, bytes1, bytes1, uint8, uint8
        ){
        uint256 length = _b.length;
        // uint256 index;
        // 0x3078 3066433530 3235433736 3463453334 6466333532 3735376538 3266374235 6334446633 3941383336
        // return (length, _b[0], _b[1], uint8(_b[0]), uint8(_b[1]));  // 42, 0x30, 0x78, 48, 120

        // if(uint8(_b[0]) == 48 && (uint8(_b[1]) == 88 || uint8(_b[1]) == 120)) { // prefix "0x" or "0X"
        //     index = 2;
        // }
        //0xddaAd340b0 f1Ef65169A e5E41A8b10 776a75482d

        uint256 numberPrefix;  // prefix "0x" or "0X" number
        for(uint256 i=0; i<length; i=i+2){    
            if(uint8(_b[i]) == 48 && (uint8(_b[i+1]) == 88 || uint8(_b[i+1]) == 120))  numberPrefix = numberPrefix + 1;  // prefix "0x" or "0X"
            
        }

        bytes memory _temp = new bytes(length/2-numberPrefix);
        uint256 j;
        for(uint256 i=0; i<length; i=i+2){    
            if(uint8(_b[i]) == 48 && (uint8(_b[i+1]) == 88 || uint8(_b[i+1]) == 120))  continue;  // prefix "0x" or "0X"
            _temp[j++] = _toBytes1(_b[i], _b[i+1]);
        }
        // _address = address(bytes20(_temp));
        return _temp;
        
    }


    function splitStringToAddressArray(string memory _s, string memory _split) public pure returns(
        address[] memory _addressList
        // bytes memory
        // uint256, uint256, uint256
        // uint256, uint256, bytes1, bytes1
        ){
        
        bytes memory _b = bytes(_s);
        bytes1 _bsplit = bytes(_split)[0];


        uint256 length = _b.length;

        // return (length, _bsplit.length);
        
        uint256 numberSplit; 
        uint256 numberPrefix;
        for(uint256 i=0; i<length-1; i++){    
            if(_b[i] == _bsplit) numberSplit = numberSplit + 1;
            if(uint8(_b[i]) == 48 && (uint8(_b[i+1]) == 88 || uint8(_b[i+1]) == 120))  numberPrefix = numberPrefix + 1;  // prefix "0x" or "0X"     
        }

        // return (length, numberSplit, numberPrefix);

        bytes memory _new = new bytes(length-numberSplit);
        numberSplit = 0;
        for(uint256 i=0; i<length; i++){    
            if(_b[i] == _bsplit) {
                numberSplit = numberSplit + 1;
                continue;
            }
            _new[i-numberSplit]=_b[i];
        }

        length = _new.length; 
        bytes memory _temp = new bytes(length/2-numberPrefix);
        uint256 j;
        for(uint256 i=0; i<length; i=i+2){    
            if(uint8(_new[i]) == 48 && (uint8(_new[i+1]) == 88 || uint8(_new[i+1]) == 120))  continue;  // prefix "0x" or "0X"
            _temp[j++] = _toBytes1(_new[i], _new[i+1]);
        }
        // _address = address(bytes20(_temp));
        // return _temp;
        _addressList = new address[](_temp.length/20);

        for(uint256 i=0; i<_addressList.length; i++){
            _addressList[i] = BytesLib.toAddress(_temp, i*20);
        }
    }




    function _toBytes1(bytes1 _b0, bytes1 _b1) private pure returns(bytes1){
        uint8 num0 = uint8(_b0);
        uint8 num1 = uint8(_b1);

        uint8 numReturn;

        uint8 _num;

        _num = num0;
        require(_num>=48 && _num<=57 || _num>=65 && _num<=70 || _num>=97 && _num<=102, "bytes error1");
        if(_num>=48 && _num<=57){ // 0~9
            numReturn = (_num-48) * 2**4;
        }else if(_num>=65 && _num<=70){ // A~F
            numReturn = (_num-55) * 2**4;
        }else{ // a~f
            numReturn = (_num-87) * 2**4;
        }

        _num = num1;
        require(_num>=48 && _num<=57 || _num>=65 && _num<=70 || _num>=97 && _num<=102, "bytes error2");
        if(_num>=48 && _num<=57){ // 0~9
            numReturn = numReturn + (_num-48);
        }else if(_num>=65 && _num<=70){ // A~F
            numReturn = numReturn + (_num-55);
        }else{ // a~f
            numReturn = numReturn + (_num-87);
        }

        return bytes1(numReturn);
        
    }


    // string "12345" => encode to bytes => 12345
    // "0" => 0x30 (ascii 48)
    // "9" => 0x39 (ascii 57)
    function getUintFromEncodeString(bytes memory _b) public pure returns(uint256 returnUint){
        uint256 length = _b.length;
        for(uint256 i=0; i<length; i++){
            uint8 num = uint8(_b[i]);
            require(num>=48 && num<=57, "incorrect input");
            returnUint = returnUint + uint256(num-48) * 10**(length-1-i);
        }

    }


    // bytes "0x1234" => 1234
    function getUintFromBytesType(bytes memory _b) public pure returns(uint256 returnUint){
        uint256 length = _b.length;
        for(uint256 i=0; i<length; i++){
            uint8 num = uint8(_b[i]);
            uint8 num0 = num / 2**4;
            uint8 num1 = num % 2**4;
            require(num0 >= 0 && num0 <=9, "incorrect input 1");
            require(num1 >= 0 && num1 <=9, "incorrect input 2");

            returnUint = returnUint + uint256(num0) * 10**(length*2-1-2*i);
            returnUint = returnUint + uint256(num1) * 10**(length*2-2-2*i);

        }
    }

    // function encodeString(string memory _s) public pure returns(bytes memory){
    //     return bytes(_s);
    // }


}