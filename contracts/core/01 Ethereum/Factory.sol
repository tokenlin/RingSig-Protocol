// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./TransferSender.sol";  
import "./WithdrawReceiver.sol"; 


import "./Supervisor.sol";
import "./Pool.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IGetRelatedAddress.sol";


contract Factory is IFactory {
    uint256[] public depositAmountsList;
    address[] public poolsList;
    address[] public ccipSendersList;
    address[] public ccipReceiversList;

    
    mapping(uint256 => address) public getPoolOfDepositAmount;

    address[4] routers = [
        0xD0daae2231E9CB96b94C8512223533293C3693Bf,  // Ethereum Sepolia
        0x70499c328e1E2a3c41108bd3730F6670a44595D1,  // Polygon Mumbai
        0xE561d5E02207fb5eB32cca20a699E0d8919a1476,  // Ethereum Mainnet
        0x3C3D92629A02a8D95D5CB9650fe49C3544f69B43  // Polygon Mainnet
    ];

    address[4] links = [
        0x779877A7B0D9E8603169DdbD7836e478b4624789,  // Ethereum Sepolia
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB,  // Polygon Mumbai
        0x514910771AF9Ca656af840dff83E8264EcF986CA,  // Ethereum Mainnet
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // Polygon Mainnet
    ];

    uint64[4] selectors = [
        16015286601757825753,  // Ethereum Sepolia
        12532609583862916517,  // Polygon Mumbai
        5009297550715157269,  // Ethereum Mainnet
        4051577828743386545  // Polygon Mainnet
    ];

    address public owner;
    address computeAddress;

    address public supervision;  // supervision contract
    address factoryEthereum;
    address factoryPolygon;
    address routerEthereum;
    address routerPolygon;
    address linkEthereum;
    address linkPolygon;
    uint64 selectorEthereum;
    uint64 selectorPolygon;

    event PoolCreatedLog(uint256 indexed _depositAmount, address indexed _pool);

    struct ParametersForPool{
        uint256 _depositAmount;
        address _owner;
        address _supervision;
        address _ccipSender;
        address _ccipReceiver;
    }
    struct ParametersForSender{
        address _pool;
        address _router;
        address _receiver;
        address _link;
        uint64 _destinationChainSelector;
    }
    struct ParametersForReceiver{
        address _pool;
        address _sender;
    }
            
    
    ParametersForPool public override parametersForPool;
    ParametersForSender public override parametersForSender;
    ParametersForReceiver public override parametersForReceiver;


    constructor(uint256 _networkType) {
        require(_networkType <= 3, "networkType error");
        if(_networkType == 0 || _networkType == 1) {  // test net
            routerEthereum = routers[0];
            routerPolygon = routers[1];
            selectorEthereum = selectors[0];
            selectorPolygon = selectors[1];
            linkEthereum = links[0];
            linkPolygon = links[1];
        }else{                                        // main net
            routerEthereum = routers[2];
            routerPolygon = routers[3];
            selectorEthereum = selectors[2];
            selectorPolygon = selectors[3];
            linkEthereum = links[2];
            linkPolygon = links[3];
        }

        owner = msg.sender;
        supervision = address(new Supervisor());
       
    }

   
    function initialize(
        address _computeAddress
        ) public {
        require(msg.sender == owner, "Only for owner!");
        require(computeAddress == address(0), "Already initialize!");
        
        computeAddress = _computeAddress;  

        (factoryEthereum, factoryPolygon) = IGetRelatedAddress(_computeAddress).getFactoryAddress();
    }



    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "Only for owner!");
        owner = _newOwner;
    }


    function create(uint256 _depositAmount) public {
        require(factoryEthereum != address(0), "factory should be set first!");
        require(owner == msg.sender, "Only for owner!");
        require(getPoolOfDepositAmount[_depositAmount] == address(0), "The depositamount alread created!");

        depositAmountsList.push(_depositAmount);

       
        (
            address _pool,
            address _transferSender,
            address _withdrawReceiver,
            address _withdrawSender,
            address _transferReceiver
        ) = IGetRelatedAddress(computeAddress).computeRelatedAddress(_depositAmount);
        
        
        _createPool(_depositAmount, _pool, _transferSender, _withdrawReceiver, _withdrawSender, _transferReceiver);
        _createCCIPSender(_depositAmount, _pool, _transferSender, _withdrawReceiver, _withdrawSender, _transferReceiver);
        _createCCIPReceiver(_depositAmount, _pool, _transferSender, _withdrawReceiver, _withdrawSender, _transferReceiver);
    }

    function _createPool(
        uint256 _depositAmount,
        address _pool,
        address _transferSender,
        address _withdrawReceiver,
        address _withdrawSender,
        address _transferReceiver
        ) internal {

        address _ccipSender;
        address _ccipReceiver;

        if(factoryEthereum == address(this)){ 
            _ccipSender = _transferSender;
            _ccipReceiver = _withdrawReceiver;           
        }else{  
            _ccipSender = _withdrawSender;
            _ccipReceiver = _transferReceiver;
        }

        parametersForPool = ParametersForPool({
            _depositAmount: _depositAmount,
            _owner: owner,
            _supervision: supervision,
            _ccipSender: _ccipSender,
            _ccipReceiver: _ccipReceiver
            });

        address _address;
        _address = address(new Pool{salt: keccak256(abi.encode(_depositAmount))}());
        delete parametersForPool;

        require(_address == _pool, "pool address different!");

        poolsList.push(_address);
       
        getPoolOfDepositAmount[_depositAmount] = _address;

        emit PoolCreatedLog(_depositAmount, _address);
    }


    function _createCCIPSender(
        uint256 _depositAmount,
        address _pool,
        address _transferSender,
        address _withdrawReceiver,
        address _withdrawSender,
        address _transferReceiver
        ) internal {

        
        if(factoryEthereum == address(this)){  
            
            parametersForSender =  ParametersForSender({
                _pool: _pool,
                _router: routerEthereum,
                _receiver: _transferReceiver,
                _link: linkEthereum,
                _destinationChainSelector: selectorPolygon
            });
            address _address;
            _address = address(new TransferSender{salt: keccak256(abi.encode(_depositAmount))}());
            delete parametersForSender;
            require(_address == _transferSender, "_transferSender address different!");
            ccipSendersList.push(_address);

        }
    }




    function _createCCIPReceiver(
        uint256 _depositAmount,
        address _pool,
        address _transferSender,
        address _withdrawReceiver,
        address _withdrawSender,
        address _transferReceiver
        ) internal{

        
        if(factoryEthereum == address(this)){  
            parametersForReceiver =  ParametersForReceiver({
                _pool: _pool,
                _sender: _withdrawSender
            });
            address _address;
            _address = address(new WithdrawReceiver{salt: keccak256(abi.encode(_depositAmount))}(routerEthereum));
            delete parametersForReceiver;
            require(_address == _withdrawReceiver, "_withdrawReceiver address different!");
            ccipReceiversList.push(_address);

        }
        
        
        
    }


    function getInfosOfIndex(uint256 _index) public view returns(
        uint256 _depositAmount, 
        address _pool,
        address _ccipSender,
        address _ccipReceiver
    ){
        _depositAmount = depositAmountsList[_index];
        _pool = poolsList[_index];
        _ccipSender = ccipSendersList[_index];
        _ccipReceiver = ccipReceiversList[_index];
    }


    function bytesCodeHash01_Pool() public pure returns(bytes32 _hash){
        bytes memory  code = type(Pool).creationCode;  
        _hash = keccak256(code);
    }





   
    function bytesCodeHash02_TransferSender() public pure returns(bytes32 _hash){
        bytes memory  code = type(TransferSender).creationCode;  
        _hash = keccak256(code);
    }
    function bytesCodeHash03_WithdrawReceiver() public view returns(bytes32 _hash){
        bytes memory  code = type(WithdrawReceiver).creationCode; 
        _hash = keccak256(abi.encodePacked(code, abi.encode(routerEthereum))); 
    }

    
}





