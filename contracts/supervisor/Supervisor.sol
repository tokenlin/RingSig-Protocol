// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Supervisor{
  
    uint256 public constant timelock = 5;  // Asset disclosure time, (s)
    address public owner;

    event Deposit(uint256 indexed index, uint256 amount,uint256 timestamp, address indexed depositor);
    mapping(address => bool) public blacklist;  // if in balcklist, can not deposit and transfer
    mapping(address => bool) public whitelist; // 
    Order[] public orders;
    struct Order{
        uint256 amount;
        uint256 timestamp;
        address depositor;
    }

    address public functionConsumer;

    constructor(address _functionConsumer) {
        owner = msg.sender;    
        functionConsumer = _functionConsumer;
    }

    function functionConsumerChange(address _new) public {
        require(msg.sender == owner, "only owner");
        functionConsumer = _new;
    }

    function deposit () public  payable{
        uint256 amount = msg.value;
        address depositor = msg.sender;
        require(amount>0);
        require(!blacklist[depositor]);

        uint256 index = orders.length;
        orders.push(Order(amount, block.timestamp, depositor));
        emit Deposit(index, amount, block.timestamp, depositor);
    }

    function report(address _blackAddress) public {
        require(!blacklist[_blackAddress]);
        blacklist[_blackAddress]=true;
    }

    function withdraw(uint256 index,uint256 _amount) public  {
        address payable sender = payable(msg.sender);
        require(isContract(sender)==false,"Not External Account");
        require(orders[index].depositor == sender,"Not Depositor");
        require(_amount<=orders[index].amount,"Insufficient balance");
        orders[index].amount = orders[index].amount - _amount;
        sender.transfer(_amount);
    }

    function transfer(uint256 index,uint256 _amount) public {
        address payable sender = payable(msg.sender);
        require(isContract(sender)==true,"Not Contract Account");
        address depositor=orders[index].depositor;
        require(blacklist[depositor]==false,"In Blacklist");
        require(orders[index].depositor == tx.origin,'Not Depositor');
        require(orders[index].timestamp+timelock<block.timestamp,"During the publicity period");
        require(_amount<=orders[index].amount,"Insufficient balance");
        orders[index].amount = orders[index].amount - _amount;
        sender.transfer(_amount);
    }
    
    function isContract(address addr) public  view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getOneAvailableOrderByAddress(address _address, uint256 _amount) public view returns(uint256, bool){
        require(blacklist[_address]==false,"In Blacklist");

        uint256 len = orders.length;

        for(uint256 i=0; i<len; i++){
            if( orders[i].depositor == _address &&
                orders[i].amount >= _amount &&
                orders[i].timestamp + timelock < block.timestamp
            ) return (i, true);
        }

        return (0, false);
    }

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


    function getBlacklist(address _address) public view returns(bool){
        if(blacklist[_address]==true) return true;
        return false;
    }

    function getWhitelist(address _address) public view returns(bool){
        if(whitelist[_address]==true) return true;
        return false;
    }




    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                   
                    tempBytes := mload(0x40)

                    let lengthmod := and(_length, 31)

                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                       
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                
                default {
                    tempBytes := mload(0x40)
                    
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }


    
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }

        return tempAddress;
    }


    function decodeToBytesFromEncodeString(bytes memory _b) public pure returns(
        bytes memory
        ){
        uint256 length = _b.length;

        uint256 numberPrefix;  
        for(uint256 i=0; i<length; i=i+2){    
            if(uint8(_b[i]) == 48 && (uint8(_b[i+1]) == 88 || uint8(_b[i+1]) == 120))  numberPrefix = numberPrefix + 1;  // prefix "0x" or "0X"
            
        }

        bytes memory _temp = new bytes(length/2-numberPrefix);
        uint256 j;
        for(uint256 i=0; i<length; i=i+2){    
            if(uint8(_b[i]) == 48 && (uint8(_b[i+1]) == 88 || uint8(_b[i+1]) == 120))  continue;
            _temp[j++] = _toBytes1(_b[i], _b[i+1]);
        }
        return _temp;
        
    }

    function _toBytes1(bytes1 _b0, bytes1 _b1) private pure returns(bytes1){
        uint8 num0 = uint8(_b0);
        uint8 num1 = uint8(_b1);

        uint8 numReturn;

        uint8 _num;

        _num = num0;
        require(_num>=48 && _num<=57 || _num>=65 && _num<=70 || _num>=97 && _num<=102, "bytes error1");
        if(_num>=48 && _num<=57){ 
            numReturn = (_num-48) * 2**4;
        }else if(_num>=65 && _num<=70){ 
            numReturn = (_num-55) * 2**4;
        }else{ 
            numReturn = (_num-87) * 2**4;
        }

        _num = num1;
        require(_num>=48 && _num<=57 || _num>=65 && _num<=70 || _num>=97 && _num<=102, "bytes error2");
        if(_num>=48 && _num<=57){ 
            numReturn = numReturn + (_num-48);
        }else if(_num>=65 && _num<=70){ 
            numReturn = numReturn + (_num-55);
        }else{ 
            numReturn = numReturn + (_num-87);
        }

        return bytes1(numReturn);
        
    }

}

