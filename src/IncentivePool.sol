// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Context} from "@openzeppelin-contracts-5.0.2/utils/Context.sol";
import {Strings} from "@openzeppelin-contracts-5.0.2/utils/Strings.sol";
import {IERC721Receiver} from "@openzeppelin-contracts-5.0.2/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin-contracts-5.0.2/token/ERC1155/IERC1155Receiver.sol";
import {EnumerableSet} from "@openzeppelin-contracts-5.0.2/utils/structs/EnumerableSet.sol";
import {MerkleProof} from "@openzeppelin-contracts-5.0.2/utils/cryptography/MerkleProof.sol";

import {ErrorHandler} from "./libraries/ErrorHandler.sol";
import {Reward, LibReward} from "./libraries/LibReward.sol";
import {LibNativeTransfer} from "./libraries/LibNativeTransfer.sol";

contract IncentivePool is Context, IERC721Receiver, IERC1155Receiver {
    using Strings for *;
    using MerkleProof for *;
    using ErrorHandler for *;
    using EnumerableSet for *;
    using LibNativeTransfer for address;

    event Refunded(address indexed to, uint256 amount);

    struct IncentiveInfo {
        uint64 startAt;
        uint64 endAt; 
        address creator; 
        Reward rewardToken; 
        uint256 tokenAmount;
        bytes bonusData;
    }

    bytes32 immutable public mRoot;
    IncentiveInfo public incentive;
    EnumerableSet.AddressSet internal claimedAddress;

    receive() external payable {}

    constructor(
        address creator_,
        Reward rewardToken_,
        uint256 rewardAmount_,
        bytes32 merkleRoot_,
        uint64 startAt_,
        uint64 duration_,
        bytes memory bonusData_
    ) payable {
        mRoot = merkleRoot_;

        incentive = IncentiveInfo({
            startAt: startAt_,
            endAt: startAt_ + duration_,
            creator: creator_,
            rewardToken: rewardToken_,
            tokenAmount: rewardAmount_,
            bonusData: bonusData_ 
        });

        if (rewardToken_.isNative()) {
            if (msg.value < rewardAmount_) revert LibReward.InsufficientAmount(rewardToken_);
            uint256 refund = msg.value - rewardAmount_;
            if (refund != 0) {
                creator_.transfer(refund, gasleft());
                emit Refunded(creator_, refund);
            }
        }
    }

    modifier validate() {
        require(_inProgressing(), "too soon / too late");
        _;
    }

    modifier onlyCreator() {
        require(_msgSender() == incentive.creator, "unauthorized");
        _;
    }

    function isClaimed(address addr) public view returns (bool) {
        return claimedAddress.contains(addr);
    }

    function claimReward(uint256 value_, bytes32[] calldata proof_, bytes calldata data_)
        external
        validate
    {
        address sender = _msgSender();
        require(!isClaimed(sender), "already claimed");
        bytes32 leaf;

        if (value_ == 0) {
            leaf = keccak256(abi.encodePacked(sender, ":", value_.toString()));
        } else {
            leaf = keccak256(abi.encodePacked(sender, ":", data_));
        }

        require(proof_.verifyCalldata(mRoot, leaf), "invalid proof");
        incentive.rewardToken.transfer(sender, value_, data_);

        claimedAddress.add(sender);
    }

    function recoverReward(uint256 value_, bytes memory data_) external onlyCreator {
        require(block.timestamp > uint256(incentive.endAt), "not started yet");
        require(!_inProgressing(), "pool in progressing");
        incentive.rewardToken.transfer(_msgSender(), value_, data_);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {}

    function _inProgressing() internal view returns (bool) {
        uint256 current = block.timestamp;
        uint256 start = uint256(incentive.startAt);
        uint256 end = uint256(incentive.endAt);
        return start <= current && current <= end;
    }
}
