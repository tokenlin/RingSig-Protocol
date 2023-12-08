// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFactory {
    function parametersForPool()
        external
        view
        returns (
            uint256 _depositAmount,
            address _owner,
            address _supervision,
            address _ccipSender,
            address _ccipReceiver
        );

    function parametersForSender()
        external
        view
        returns (
            address _pool,
            address _router,
            address _receiver,
            address _link,
            uint64 _destinationChainSelector
        );

    function parametersForReceiver()
        external
        view
        returns (
            address _pool,
            address _sender
        );
}
