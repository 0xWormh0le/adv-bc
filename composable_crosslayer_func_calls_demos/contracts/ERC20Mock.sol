// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 _decimals;

    constructor(string memory _name,  string memory _symbol) ERC20(_name, _symbol) {
           _decimals = 18;
    }

    function setBalanceTo(address to, uint256 value) public {
        _mint(to, value);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

}