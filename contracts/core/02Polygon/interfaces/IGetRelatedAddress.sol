// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGetRelatedAddress {
    function computeRelatedAddress(
        uint256 _depositAmount
        ) external view returns(
        address _pool,
        address _transferSender,
        address _withdrawReceiver,
        address _withdrawSender,
        address _transferReceiver
    );

    function getFactoryAddress() external view returns(
        address _FactoryEthereum,
        address _FactoryPolygon
    );

}
