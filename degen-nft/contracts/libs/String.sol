// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library String {
    function empty(string memory value) internal pure returns (bool) {
        return bytes(value).length == 0;
    }
}
