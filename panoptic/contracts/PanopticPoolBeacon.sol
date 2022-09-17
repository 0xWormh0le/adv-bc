// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/IBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PanopticPoolBeacon is IBeacon, Ownable {
    address public override implementation;

    constructor(address _owner, address _implementation) {
        implementation = _implementation;
        transferOwnership(_owner);
    }

    function upgradeImplementation(address _newImplementation) external onlyOwner {
        implementation = _newImplementation;
    }
}
