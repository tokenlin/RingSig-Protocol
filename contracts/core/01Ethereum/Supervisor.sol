// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/ISupervisor.sol";



contract Supervisor is ISupervisor{
    
    uint256 public constant timelock = 5;  // Asset disclosure time, (s)
    address public owner;

    event Deposit(uint256 indexed index, uint256 amount,uint256 timestamp, address indexed depositor);
    mapping(address => bool) public blacklist;  // if in balcklist, can not deposit and transfer
    Order[] public orders;
    struct Order{
        
        uint256 amount;
        uint256 timestamp;
        address depositor;
    }

    constructor() {
        owner = msg.sender;
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

    // anyone can submit who has questions about this address
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
        // orders[index].amount = orders[index].amount.sub(_amount);
        sender.transfer(_amount);
    }

    function transfer(uint256 index,uint256 _amount) public   {
        address payable sender = payable(msg.sender);
        require(isContract(sender)==true,"Not Contract Account");
        address depositor=orders[index].depositor;
        require(blacklist[depositor]==false,"In Blacklist");
        require(orders[index].depositor == tx.origin,'Not Depositor');
        require(orders[index].timestamp+timelock<block.timestamp,"During the publicity period");
        require(_amount<=orders[index].amount,"Insufficient balance");
        orders[index].amount = orders[index].amount - _amount;
        // orders[index].amount = orders[index].amount.sub(_amount);
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
}