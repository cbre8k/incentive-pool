// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Context} from "@openzeppelin-contracts-5.0.2/utils/Context.sol";
import {Reward, IncentivePool} from "./IncentivePool.sol";

contract IncentiveFactory is Context {
    event PoolCreated(address owner, address pool);

    function createPoolIncentive(
        Reward rewardToken_,
        uint256 rewardAmount_,
        bytes calldata rewardData_,
        bytes32 merkleRoot_,
        uint64 claimStart_,
        uint64 claimDuration_
    ) external payable {
        address _pool = address(
            new IncentivePool{value: msg.value}(
                _msgSender(),
                rewardToken_,
                rewardAmount_,
                merkleRoot_,
                claimStart_,
                claimDuration_,
                rewardData_
            )
        );
        rewardToken_.transferFrom(_msgSender(), _pool, rewardAmount_, rewardData_);

        emit PoolCreated(_msgSender(), _pool);
    }
}
