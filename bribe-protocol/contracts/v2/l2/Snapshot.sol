//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

abstract contract ReceiptTokenSnapshot {
    struct Snapshot {
        uint256[] blockNumbers;
        uint256[] amounts;
    }

    /// @dev account balance snapshots
    mapping(string => mapping(address => Snapshot)) private _accountBalanceSnapshots;

    /**
     * @dev _tokenTransfer
     */
    function _tokenTransfer(
        string memory pool,
        address from,
        address to,
        uint256 fromBalance,
        uint256 toBalance,
        uint256 transferAmount,
        uint256 blockNumber
    ) internal {
        if (from != address(0)) {
            _updateSnapshot(
                _accountBalanceSnapshots[pool][from],
                fromBalance - transferAmount,
                blockNumber
            );
        }

        if (to != address(0)) {
            _updateSnapshot(
                _accountBalanceSnapshots[pool][to],
                toBalance + transferAmount,
                blockNumber
            );
        }
    }

    function _updateSnapshot(
        Snapshot storage userSnapshots,
        uint256 newValue,
        uint256 blockNumber
    ) private {
        uint256 size = userSnapshots.blockNumbers.length;

        // multiple snapshots in the current block
        if (size > 0 && userSnapshots.blockNumbers[size - 1] == blockNumber) {
            userSnapshots.amounts[size - 1] = newValue;
        } else {
            userSnapshots.blockNumbers.push(blockNumber);
            userSnapshots.amounts.push(newValue);
        }
    }

    function _balanceOf(string memory pool, address user) internal view returns (uint256 amount) {
        amount = _getDepositAt(pool, user, type(uint256).max);
    }

    /**
     * @dev getDepositAt user deposit at blockNumber or closest to blockNumber
     */
    function _getDepositAt(
        string memory pool,
        address user,
        uint256 blockNumber
    ) internal view returns (uint256 amount) {
        Snapshot storage userSnapshots = _accountBalanceSnapshots[pool][user];
        uint256 size = userSnapshots.blockNumbers.length;

        if (size == 0) return 0;

        // check if the user latest and least deposit are within range of blockNumber
        if (userSnapshots.blockNumbers[0] > blockNumber) {
            return 0;
        }

        if (userSnapshots.blockNumbers[size - 1] <= blockNumber) {
            return userSnapshots.amounts[size - 1];
        }

        return _searchByBlockNumber(userSnapshots, size, blockNumber);
    }

    /**
     * @dev _searchByProposalId searches the reward snapshot by blockNumber. Uses binary search.
     * @param snapshot reward
     * @param blockNumber proposalId
     */
    function _searchByBlockNumber(
        Snapshot storage snapshot,
        uint256 snapshotSize,
        uint256 blockNumber
    ) private view returns (uint256 amount) {
        uint256 lower = 0;
        uint256 upper = snapshotSize - 1;

        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            if (snapshot.blockNumbers[center] == blockNumber) {
                return snapshot.amounts[center];
            } else if (snapshot.blockNumbers[center] < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }

        return snapshot.amounts[lower];
    }
}
