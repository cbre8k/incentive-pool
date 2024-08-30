// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibNativeTransfer} from "./LibNativeTransfer.sol";
import {IERC721} from "@openzeppelin-contracts-5.0.2/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin-contracts-5.0.2/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin-contracts-5.0.2/utils/introspection/IERC165.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin-contracts-5.0.2/token/ERC20/extensions/IERC20Metadata.sol";

type Reward is address;

using {eq as ==} for Reward global;
using LibReward for Reward global;

function eq(Reward self, Reward other) pure returns (bool) {
    return Reward.unwrap(self) == Reward.unwrap(other);
}

library LibReward {
    error TransferZeroAmount(Reward reward);
    error InsufficientAmount(Reward reward);
    error InvalidReceiveFrom(address receiveFrom);

    using SafeERC20 for IERC20Metadata;
    using LibNativeTransfer for address;

    uint8 private constant NATIVE_DECIMAL = 18;
    Reward internal constant NATIVE = Reward.wrap(address(0x0));

    function isNative(Reward reward) internal pure returns (bool) {
        return reward == NATIVE;
    }

    function isERC721(Reward reward) internal view returns (bool) {
        return IERC165(Reward.unwrap(reward)).supportsInterface(type(IERC721).interfaceId);
    }

    function transfer(Reward reward, address to, uint256 value, bytes memory data) internal {
        if (data.length == 0) {
            if (value == 0) revert TransferZeroAmount(reward);
            if (isNative(reward)) {
                to.transfer(value, gasleft());
            } else {
                IERC20Metadata(Reward.unwrap(reward)).safeTransfer(to, value);
            }
        } else {
            if (isERC721(reward)) {
                uint256[] memory ids = abi.decode(data, (uint256[]));
                for (uint256 i; i < ids.length; ++i) {
                    IERC721(Reward.unwrap(reward)).safeTransferFrom(address(this), to, ids[i]);
                }
            } else {
                (uint256[] memory ids, uint256[] memory values) = abi.decode(data, (uint256[], uint256[]));
                IERC1155(Reward.unwrap(reward)).safeBatchTransferFrom(address(this), to, ids, values, "");
            }
        }
    }

    function transferFrom(Reward reward, address from, address to, uint256 value, bytes memory data) internal {
        if (data.length == 0) {
            if (value == 0) revert TransferZeroAmount(reward);
            if (isNative(reward)) {
                if (from != msg.sender) revert InvalidReceiveFrom(from);
            } else {
                IERC20Metadata(Reward.unwrap(reward)).transferFrom(from, to, value);
            }
        } else {
            if (isERC721(reward)) {
                uint256[] memory ids = abi.decode(data, (uint256[]));
                for (uint256 i; i < ids.length; ++i) {
                    IERC721(Reward.unwrap(reward)).safeTransferFrom(from, to, ids[i]);
                }
            } else {
                (uint256[] memory ids, uint256[] memory values) = abi.decode(data, (uint256[], uint256[]));
                IERC1155(Reward.unwrap(reward)).safeBatchTransferFrom(from, to, ids, values, "");
            }
        }
    }
}
